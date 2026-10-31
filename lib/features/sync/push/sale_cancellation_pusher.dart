import 'package:uuid/uuid.dart';

import '../../../core/services/database.helper.dart';
import '../../inventory/data/repositories/inventory.repository.dart';
import '../../sales/data/repositories/drift.sale.repository.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Sale cancellations, after the sales and payments they refer to.
class SaleCancellationPusher implements EntityPusher, RejectionAware {
  SaleCancellationPusher(this._db, {DateTime Function()? today})
    : _sales = DriftSaleRepository(_db),
      _inventory = DriftInventoryRepository(_db),
      _today = today ?? DateTime.now;

  static const missing = 'La venta anulada ya no existe en el dispositivo.';

  final AppDatabase _db;
  final DriftSaleRepository _sales;
  final DriftInventoryRepository _inventory;
  final DateTime Function() _today;

  @override
  PendingEntity get entity => PendingEntity.saleCancellation;

  @override
  String get wireKey => 'sale_cancellations';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final idsBySale = <String, List<int>>{};
    for (final c in changes) {
      idsBySale.putIfAbsent(c.entityId, () => []).add(c.id);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    for (final MapEntry(key: saleId, value: ids) in idsBySale.entries) {
      final sale = await (_db.select(
        _db.saleTable,
      )..where((t) => t.saleId.equals(saleId))).getSingleOrNull();
      if (sale == null || sale.cancelledAt == null) {
        rejections.add(LocalRejection(ids, missing));
        continue;
      }
      // The sale waits for its open visit, so its cancellation waits too.
      if (await awaitsOpenVisit(_db, sale.visitId, today: _today())) continue;

      final uuid = cancellationUuid('sale', saleId, ids.first);
      records.add(
        PushRecord(
          uuid: uuid,
          localId: saleId,
          changeIds: ids,
          body: {
            'uuid': uuid,
            ...reference('sale', serverId: sale.serverId, uuid: saleId),
            'cancelled_at': sale.cancelledAt!.toUtc().toIso8601String(),
            'reason': sale.cancellationReason,
          },
        ),
      );
    }
    return PushPlan(records: records, rejections: rejections);
  }

  /// The server answers the sale's own id, which the sale already has.
  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {}

  /// The sale counts again: in the balance, the truck stock and custody.
  @override
  Future<void> applyRejected(String localId, {Json? current}) async {
    await _sales.undoCancellation(localId);
    await _inventory.undoSaleReversal(localId);
  }
}

/// The client uuid of the cancellation of [entity] [localId] queued as
/// [changeId]: stable across retries, new for a later cancellation.
String cancellationUuid(String entity, String localId, int changeId) =>
    const Uuid().v5(
      Namespace.url.value,
      '$entity-cancellation/$localId/$changeId',
    );
