import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// Route stops. A stop with an unsent change (or an unsent visit) keeps its
/// local copy.
class StopApplier implements PullApplier {
  StopApplier(this._db);

  final AppDatabase _db;

  /// Stops already stored keep their sequence; new ones go to the end of
  /// their route. A stop created by the app is matched by its client uuid.
  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final s in rows['route_stops'] ?? const <Json>[]) {
      final route = await context.ids.route(s['route_id'] as int?);
      final customerId = await context.ids.customer(s['customer_id'] as int?);
      if (route == null || customerId == null) continue;
      final serverId = s['id'] as int;
      final clientUuid = s['client_uuid'] as String?;
      final existing =
          await (_db.select(_db.routeStopTable)..where(
                (t) =>
                    t.serverId.equals(serverId) |
                    (clientUuid == null
                        ? const Constant(false)
                        : t.routeStopId.equals(clientUuid)),
              ))
              .getSingleOrNull();
      if (existing != null &&
          context.unsent.stops.contains(existing.routeStopId)) {
        continue;
      }

      final time = s['scheduled_time'] as String?;
      final fields = RouteStopTableCompanion(
        routeId: Value(route.routeId),
        customerId: Value(customerId),
        customerAddressId: Value(
          await context.ids.address(s['address_id'] as int?),
        ),
        status: Value(_status(s['status'] as String?)),
        scheduledAt: Value(_scheduledAt(route.route_date, time)),
        scheduledTime: Value(time),
        rescheduledFromStopId: Value(
          await context.ids.stop(s['is_rescheduled_from'] as int?),
        ),
        enabled: enabledOf(s),
        serverId: Value(serverId),
      );
      if (existing != null) {
        await (_db.update(_db.routeStopTable)
              ..where((t) => t.routeStopId.equals(existing.routeStopId)))
            .write(fields);
        continue;
      }
      final maxSequence = _db.routeStopTable.sequence.max();
      final last =
          await (_db.selectOnly(_db.routeStopTable)
                ..addColumns([maxSequence])
                ..where(_db.routeStopTable.routeId.equals(route.routeId)))
              .map((r) => r.read(maxSequence))
              .getSingle();
      await _db
          .into(_db.routeStopTable)
          .insert(
            fields.copyWith(
              routeStopId: clientUuid == null
                  ? const Value.absent()
                  : Value(clientUuid),
              sequence: Value((last ?? 0) + 1),
            ),
          );
    }
  }

  /// The bootstrap carries the stops of [routeId] in order: the sequence is
  /// their position, and a reschedule links to a stop of the same download.
  Future<void> replaceRoute(
    String routeId,
    List<Json> stops,
    PullContext context,
  ) async {
    final route = await (_db.select(
      _db.routeTable,
    )..where((t) => t.routeId.equals(routeId))).getSingle();

    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      final serverId = s['id'] as int;
      final customerId = await context.ids.customer(s['customer_id'] as int);
      if (customerId == null) continue;
      final time = s['scheduled_time'] as String?;
      final fields = RouteStopTableCompanion(
        routeId: Value(routeId),
        customerId: Value(customerId),
        customerAddressId: Value(
          await context.ids.address(s['address_id'] as int?),
        ),
        sequence: Value(i + 1),
        status: Value(_status(s['status'] as String?)),
        scheduledAt: Value(_scheduledAt(route.route_date, time)),
        scheduledTime: Value(time),
        serverId: Value(serverId),
      );
      final existing = await (_db.select(
        _db.routeStopTable,
      )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
      if (existing == null) {
        final row = await _db.into(_db.routeStopTable).insertReturning(fields);
        context.ids.recordStop(serverId, row.routeStopId);
      } else {
        if (!context.unsent.stops.contains(existing.routeStopId)) {
          await (_db.update(_db.routeStopTable)
                ..where((t) => t.routeStopId.equals(existing.routeStopId)))
              .write(fields);
        }
        context.ids.recordStop(serverId, existing.routeStopId);
      }
    }

    for (final s in stops) {
      final localId = await context.ids.stop(s['id'] as int);
      if (localId == null) continue;
      final from = s['is_rescheduled_from'] as int?;
      await (_db.update(
        _db.routeStopTable,
      )..where((t) => t.routeStopId.equals(localId))).write(
        RouteStopTableCompanion(
          rescheduledFromStopId: Value(
            from == null ? null : await context.ids.stop(from),
          ),
        ),
      );
    }
  }

  static String _status(String? serverStatus) => switch (serverStatus) {
    'FINISHED' => 'done',
    'RESCHEDULED' => 'rescheduled',
    'CANCELLED' => 'absent',
    _ => 'pending',
  };

  static DateTime _scheduledAt(String date, String? time) {
    final day = DateTime.parse(date);
    if (time == null) return day;
    final parts = time.split(':').map(int.parse).toList();
    return DateTime(day.year, day.month, day.day, parts[0], parts[1]);
  }
}
