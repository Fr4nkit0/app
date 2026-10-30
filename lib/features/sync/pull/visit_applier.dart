import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// Today's visits, carried only by the bootstrap so a reinstalled device
/// rebuilds the day's work; the incremental pull does not send them.
///
/// Rows are written directly, never through the visit repository: the
/// server already has them, so nothing is queued for push.
class VisitApplier {
  VisitApplier(this._db);

  final AppDatabase _db;

  /// A visit already on the device (by client uuid or server id) is linked
  /// to its server id; one with unsent changes keeps its local values. A
  /// visit whose stop or customer the download did not carry is dropped.
  Future<void> storeToday(List<Json> visits, PullContext context) async {
    for (final v in visits) {
      final serverId = v['id'] as int;
      final stopId = await context.ids.stop(v['route_stop_id'] as int?);
      final customerId = await context.ids.customer(v['customer_id'] as int?);
      if (stopId == null || customerId == null) continue;
      final clientUuid = v['client_uuid'] as String?;
      final existing =
          await (_db.select(_db.visitTable)..where(
                (t) =>
                    t.serverId.equals(serverId) |
                    (clientUuid == null
                        ? const Constant(false)
                        : t.visitId.equals(clientUuid)),
              ))
              .getSingleOrNull();

      final fields = VisitTableCompanion(
        routeStopId: Value(stopId),
        customerId: Value(customerId),
        outcomeId: Value(v['outcome_id'] as int?),
        arrived_at: Value(DateTime.parse(v['arrived_at'] as String).toLocal()),
        observations: Value(v['notes'] as String?),
        serverId: Value(serverId),
      );
      final String visitId;
      if (existing == null) {
        visitId =
            (await _db
                    .into(_db.visitTable)
                    .insertReturning(
                      fields.copyWith(
                        visitId: clientUuid == null
                            ? const Value.absent()
                            : Value(clientUuid),
                        visitType: const Value('visit'),
                      ),
                    ))
                .visitId;
      } else {
        visitId = existing.visitId;
        await (_db.update(
          _db.visitTable,
        )..where((t) => t.visitId.equals(visitId))).write(
          context.unsent.visits.contains(visitId)
              ? VisitTableCompanion(serverId: Value(serverId))
              : fields,
        );
      }
      context.ids.recordVisit(serverId, visitId);
    }
  }
}
