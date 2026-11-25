import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';

/// The driver's order of the stops of a route for the day.
///
/// Each reorder queues the whole route as a snapshot; only the latest one
/// of a route is sent, the older ones are settled with it (the server keeps
/// the last order it receives). A stop travels by its server id, or by its
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
      settled.addAll([
        for (final c in routeChanges)
          if (c.id != latest.id) c.id,
      ]);

      final route = await (_db.select(
        _db.routeTable,
      )..where((t) => t.routeId.equals(routeId))).getSingleOrNull();
      final routeServerId = route?.serverId;
      if (routeServerId == null) {
        rejections.add(LocalRejection([latest.id], routeNotOnServer));
        continue;
      }

      final stopIds = [
        for (final id in latest.payload?['stops'] as List? ?? const [])
          id as String,
      ];
      final rows = await (_db.select(
        _db.routeStopTable,
      )..where((t) => t.routeStopId.isIn(stopIds))).get();
      final serverIdOf = {for (final r in rows) r.routeStopId: r.serverId};
      final uuid =
          latest.payload?['uuid'] as String? ?? '$routeId-${latest.id}';
      records.add(
        PushRecord(
          uuid: uuid,
          localId: routeId,
          changeIds: [latest.id],
          body: {
            'uuid': uuid,
            'route_id': routeServerId,
            'stops': [
              for (final id in stopIds)
                if (serverIdOf.containsKey(id))
                  serverIdOf[id] != null
                      ? {'id': serverIdOf[id]}
                      : {'uuid': id},
            ],
          },
        ),
      );
    }
    return PushPlan(records: records, rejections: rejections, settled: settled);
  }

  /// The server answers with the route's id, which the route already has.
  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {}
}
