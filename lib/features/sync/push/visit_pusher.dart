import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Visits recorded on the street, rebuilt from the local row.
class VisitPusher implements EntityPusher {
  VisitPusher(this._db);

  static const missing = 'La visita ya no existe en el dispositivo.';

  final AppDatabase _db;

  @override
  PendingEntity get entity => PendingEntity.visit;

  @override
  String get wireKey => 'visits';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final idsByVisit = <String, List<int>>{};
    for (final c in changes) {
      idsByVisit.putIfAbsent(c.entityId, () => []).add(c.id);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    for (final MapEntry(key: visitId, value: ids) in idsByVisit.entries) {
      final visit = await (_db.select(
        _db.visitTable,
      )..where((t) => t.visitId.equals(visitId))).getSingleOrNull();
      if (visit == null) {
        rejections.add(LocalRejection(ids, missing));
        continue;
      }
      records.add(
        PushRecord(uuid: visitId, changeIds: ids, body: await _body(visit)),
      );
    }
    return PushPlan(records: records, rejections: rejections);
  }

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    await (_db.update(_db.visitTable)
          ..where((t) => t.visitId.equals(record.uuid)))
        .write(VisitTableCompanion(serverId: Value(serverId)));
  }

  Future<Json> _body(VisitTableData visit) async {
    final customer = await (_db.select(
      _db.customerTable,
    )..where((t) => t.customerId.equals(visit.customerId))).getSingleOrNull();
    final stop = await (_db.select(
      _db.routeStopTable,
    )..where((t) => t.routeStopId.equals(visit.routeStopId))).getSingleOrNull();
    return {
      'uuid': visit.visitId,
      ...reference(
        'customer',
        serverId: customer?.serverId,
        uuid: visit.customerId,
      ),
      ...reference(
        'route_stop',
        serverId: stop?.serverId,
        uuid: visit.routeStopId,
      ),
      'outcome_id': visit.outcomeId,
      'arrived_at': visit.arrived_at.toUtc().toIso8601String(),
      'notes': visit.observations,
    };
  }
}
