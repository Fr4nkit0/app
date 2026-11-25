import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';

/// The driver's order of the stops of a route for the day.
///
/// Each reorder queues the whole route as a snapshot; only the latest one
/// of a route is sent, the older ones are settled with it (the server keeps
/// the last order it receives). A snapshot that also rewrites the driver's
/// pile for the coming weekdays is never dropped by a later today-only one. A stop travels by its server id, or by its
/// client uuid when the server does not have it yet (a reschedule sent in
/// the same request, which the server processes after `route_stops`).
class RouteStopOrderPusher implements EntityPusher {
  RouteStopOrderPusher(this._db);

  static const routeNotOnServer = 'La ruta todavía no está en el servidor.';

  final AppDatabase _db;

  @override
  PendingEntity get entity => PendingEntity.routeStopOrder;

  @override
  String get wireKey => 'route_stop_orders';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final byRoute = <String, List<PendingChange>>{};
    for (final c in changes) {
      byRoute.putIfAbsent(c.entityId, () => []).add(c);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    final settled = <int>[];
    for (final MapEntry(key: routeId, value: routeChanges) in byRoute.entries) {
      routeChanges.sort((a, b) => a.id.compareTo(b.id));
      final latest = routeChanges.last;
      // A today-only reorder after an unsent one for the coming weekdays
      // must not drop the pile: that one travels first, then the latest.
      final pile = _appliesToTemplate(latest)
          ? null
          : routeChanges.reversed.where(_appliesToTemplate).firstOrNull;
      final sent = [?pile, latest];
      settled.addAll([
        for (final c in routeChanges)
          if (!sent.contains(c)) c.id,
      ]);

      final route = await (_db.select(
        _db.routeTable,
      )..where((t) => t.routeId.equals(routeId))).getSingleOrNull();
      final routeServerId = route?.serverId;
      if (routeServerId == null) {
        rejections.add(
          LocalRejection([for (final c in sent) c.id], routeNotOnServer),
        );
        continue;
      }
      for (final change in sent) {
        records.add(await _record(routeId, routeServerId, change));
      }
    }
    return PushPlan(records: records, rejections: rejections, settled: settled);
  }

  Future<PushRecord> _record(
    String routeId,
    int routeServerId,
    PendingChange change,
  ) async {
    final stopIds = [
      for (final id in change.payload?['stops'] as List? ?? const [])
        id as String,
    ];
    final rows = await (_db.select(
      _db.routeStopTable,
    )..where((t) => t.routeStopId.isIn(stopIds))).get();
    final serverIdOf = {for (final r in rows) r.routeStopId: r.serverId};
    final uuid = change.payload?['uuid'] as String? ?? '$routeId-${change.id}';
    return PushRecord(
      uuid: uuid,
      localId: routeId,
      changeIds: [change.id],
      body: {
        'uuid': uuid,
        'route_id': routeServerId,
        'stops': [
          for (final id in stopIds)
            if (serverIdOf.containsKey(id))
              serverIdOf[id] != null ? {'id': serverIdOf[id]} : {'uuid': id},
        ],
        'apply_to_template': _appliesToTemplate(change),
      },
    );
  }

  static bool _appliesToTemplate(PendingChange change) =>
      change.payload?['applyToTemplate'] == true;

  /// The server answers with the route's id, which the route already has.
  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {}
}
