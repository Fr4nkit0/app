import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// Route stops. A stop with an unsent change (or an unsent visit) keeps its
/// local copy. A stop may carry a visit the admin scheduled (its mark and
/// note); a stop created only for a cancelled visit arrives disabled.
class StopApplier implements PullApplier {
  StopApplier(this._db);

  final AppDatabase _db;

  /// Stops already stored keep their sequence; new ones go to the end of
  /// their route. The server's route position applies unless the route has
  /// an unsent reorder of the driver. A stop created by the app is matched
  /// by its client uuid.
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
      final keepsOrder = context.unsent.orderedRoutes.contains(route.routeId);
      final fields = RouteStopTableCompanion(
        routeId: Value(route.routeId),
        // A new stop of a route the driver reordered goes after the
        // positioned stops until the server has the driver's order.
        position: keepsOrder
            ? (existing == null ? const Value(null) : const Value.absent())
            : _position(s),
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
        isRequested: _isRequested(s),
        note: _note(s),
        isCover: _isCover(s),
        coveredDriverName: _coveredDriverName(s),
        scheduledVisitId: s.containsKey('scheduled_visit_id')
            ? Value(s['scheduled_visit_id'] as int?)
            : const Value.absent(),
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

    final keepsOrder = context.unsent.orderedRoutes.contains(routeId);
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      final serverId = s['id'] as int;
      final customerId = await context.ids.customer(s['customer_id'] as int);
      if (customerId == null) continue;
      final time = s['scheduled_time'] as String?;
      final fields = RouteStopTableCompanion(
        routeId: Value(routeId),
        position: _position(s),
        customerId: Value(customerId),
        customerAddressId: Value(
          await context.ids.address(s['address_id'] as int?),
        ),
        sequence: Value(i + 1),
        status: Value(_status(s['status'] as String?)),
        scheduledAt: Value(_scheduledAt(route.route_date, time)),
        scheduledTime: Value(time),
        isRequested: _isRequested(s),
        note: _note(s),
        isCover: _isCover(s),
        coveredDriverName: _coveredDriverName(s),
        serverId: Value(serverId),
      );
      final existing = await (_db.select(
        _db.routeStopTable,
      )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
      if (existing == null) {
        final row = await _db
            .into(_db.routeStopTable)
            .insertReturning(
              keepsOrder
                  ? fields.copyWith(position: const Value(null))
                  : fields,
            );
        context.ids.recordStop(serverId, row.routeStopId);
      } else {
        if (!context.unsent.stops.contains(existing.routeStopId)) {
          await (_db.update(
            _db.routeStopTable,
          )..where((t) => t.routeStopId.equals(existing.routeStopId))).write(
            keepsOrder
                ? fields.copyWith(position: const Value.absent())
                : fields,
          );
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

  /// A server older than route order sends no position: the stored one
  /// stays.
  static Value<int?> _position(Json s) => s.containsKey('position')
      ? Value(s['position'] as int?)
      : const Value.absent();

  /// A server older than scheduled visits sends no mark: the stored one
  /// stays, and a new stop is not requested.
  static Value<bool> _isRequested(Json s) => s.containsKey('is_requested')
      ? Value(s['is_requested'] == true)
      : const Value.absent();

  static Value<String?> _note(Json s) => s.containsKey('note')
      ? Value(s['note'] as String?)
      : const Value.absent();

  /// A server older than route covers sends no mark: the stored one stays,
  /// and a new stop is an own stop.
  static Value<bool> _isCover(Json s) => s.containsKey('is_cover')
      ? Value(s['is_cover'] == true)
      : const Value.absent();

  static Value<String?> _coveredDriverName(Json s) =>
      s.containsKey('covered_driver_name')
      ? Value(s['covered_driver_name'] as String?)
      : const Value.absent();

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
