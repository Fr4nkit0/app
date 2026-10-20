import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Stops the app creates: reschedules later the same day (ADR 0002).
///
/// The server owns stops, so a status change of an existing stop is not
/// sent: the server derives it from the stop's visit (and marks the original
/// of a reschedule as rescheduled), so those changes settle on their own.
class RouteStopPusher implements EntityPusher {
  RouteStopPusher(this._db);

  static const deletedLocally = 'The stop no longer exists on the device.';
  static const notRescheduled =
      'Only stops rescheduled the same day are created by the app.';

  final AppDatabase _db;

  @override
  PendingEntity get entity => PendingEntity.routeStop;

  @override
  String get wireKey => 'route_stops';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final byStop = <String, List<PendingChange>>{};
    for (final c in changes) {
      byStop.putIfAbsent(c.entityId, () => []).add(c);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    final settled = <int>[];
    for (final MapEntry(key: stopId, value: stopChanges) in byStop.entries) {
      final ids = [for (final c in stopChanges) c.id];
      final created = stopChanges.any((c) => c.action == PendingAction.insert);
      if (!created) {
        settled.addAll(ids);
        continue;
      }
      final stop = await _stop(stopId);
      if (stop == null) {
        rejections.add(LocalRejection(ids, deletedLocally));
        continue;
      }
      final fromId = stop.rescheduledFromStopId;
      final from = fromId == null ? null : await _stop(fromId);
      final time = stop.scheduledTime;
      if (fromId == null || time == null) {
        rejections.add(LocalRejection(ids, notRescheduled));
        continue;
      }
      records.add(
        PushRecord(
          uuid: stopId,
          changeIds: ids,
          body: {
            'uuid': stopId,
            ...reference(
              'rescheduled_from',
              serverId: from?.serverId,
              uuid: fromId,
            ),
            // The server takes HH:mm.
            'scheduled_time': time.substring(0, 5),
          },
        ),
      );
    }
    return PushPlan(
      records: records,
      rejections: rejections,
      settled: settled,
    );
  }

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    await (_db.update(_db.routeStopTable)
          ..where((t) => t.routeStopId.equals(record.uuid)))
        .write(RouteStopTableCompanion(serverId: Value(serverId)));
  }

  Future<RouteStopTableData?> _stop(String id) => (_db.select(
    _db.routeStopTable,
  )..where((t) => t.routeStopId.equals(id))).getSingleOrNull();
}
