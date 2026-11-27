import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../../balance_corrections/data/repositories/balance_correction.repository.dart';
import '../../balance_corrections/domain/models/balance_correction.dart';
import '../domain/models/pending_change.dart';
import 'container_movement_pusher.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Balance corrections: the debt or the custody of one container type the
/// driver counted, with the balance the device showed. The server adds the
/// same difference (`counted - seen_balance`) the device already applied;
/// a rejection takes it back out.
class BalanceCorrectionPusher implements EntityPusher, RejectionAware {
  BalanceCorrectionPusher(this._db, {DateTime Function()? today})
    : _corrections = DriftBalanceCorrectionRepository(_db),
      _today = today ?? DateTime.now;

  static const missing =
      'La corrección de saldo ya no existe en el dispositivo.';

  final AppDatabase _db;
  final BalanceCorrectionRepository _corrections;
  final DateTime Function() _today;

  @override
  PendingEntity get entity => PendingEntity.balanceCorrection;

  @override
  String get wireKey => 'balance_corrections';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final idsByCorrection = <String, List<int>>{};
    for (final c in changes) {
      idsByCorrection.putIfAbsent(c.entityId, () => []).add(c.id);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    for (final MapEntry(key: correctionId, value: ids)
        in idsByCorrection.entries) {
      final correction = await (_db.select(
        _db.balanceCorrectionTable,
      )..where((t) => t.correctionId.equals(correctionId))).getSingleOrNull();
      if (correction == null) {
        rejections.add(LocalRejection(ids, missing));
        continue;
      }
      // Its visit is still open: it waits so it travels linked to it.
      if (await awaitsOpenVisit(_db, correction.visitId, today: _today())) {
        continue;
      }
      final target = BalanceTarget.fromWire(correction.target);
      int? typeId;
      if (target == BalanceTarget.containers) {
        final code = correction.containerType ?? '';
        final type = await (_db.select(
          _db.containerTypeTable,
        )..where((t) => t.code.equals(code))).getSingleOrNull();
        if (type == null) {
          rejections.add(
            LocalRejection(ids, ContainerMovementPusher.unknownType(code)),
          );
          continue;
        }
        typeId = type.id;
      }

      final visit = await resolveVisit(_db, correction.visitId);
      records.add(
        PushRecord(
          uuid: correctionId,
          changeIds: ids,
          body: {
            'uuid': correctionId,
            ...await customerReference(_db, correction.customerId),
            if (visit != null)
              ...reference(
                'visit',
                serverId: visit.serverId,
                uuid: visit.visitId,
              ),
            'target': target.wireName,
            'container_type_id': ?typeId,
            'counted': correction.counted,
            'seen_balance': correction.seenBalance,
            'reason': correction.reason,
            'corrected_at': correction.correctedAt.toUtc().toIso8601String(),
          },
        ),
      );
    }
    return PushPlan(records: records, rejections: rejections);
  }

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    await (_db.update(_db.balanceCorrectionTable)
          ..where((t) => t.correctionId.equals(record.localId)))
        .write(BalanceCorrectionTableCompanion(serverId: Value(serverId)));
  }

  @override
  Future<void> applyRejected(String localId, {Json? current}) =>
      _corrections.takeBack(localId);
}
