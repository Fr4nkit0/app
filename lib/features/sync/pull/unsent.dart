import '../../../core/services/database.helper.dart';
import '../domain/models/pending_change.dart';

/// Local rows that still have unsent or rejected changes; the server copy
/// must not overwrite them.
class Unsent {
  const Unsent({
    required this.customers,
    required this.stops,
    required this.hasSales,
  });

  final Set<String> customers;
  final Set<String> stops;
  final bool hasSales;

  /// Reads the queue; a stop with an unsent visit counts as unsent.
  static Future<Unsent> load(AppDatabase db) async {
    final rows =
        await (db.select(db.pendingChangeTable)..where(
              (t) => t.status.isIn([
                PendingStatus.pending.wireName,
                PendingStatus.rejected.wireName,
              ]),
            ))
            .get();
    Set<String> ids(PendingEntity e) => {
      for (final r in rows)
        if (r.entity == e.wireName) r.entityId,
    };

    final visitIds = ids(PendingEntity.visit);
    final stops = ids(PendingEntity.routeStop);
    if (visitIds.isNotEmpty) {
      final visits = await (db.select(
        db.visitTable,
      )..where((t) => t.visitId.isIn(visitIds))).get();
      stops.addAll(visits.map((v) => v.routeStopId));
    }

    return Unsent(
      customers: ids(PendingEntity.customer),
      stops: stops,
      hasSales: ids(PendingEntity.sale).isNotEmpty,
    );
  }
}
