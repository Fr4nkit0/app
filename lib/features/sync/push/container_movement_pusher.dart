import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database.helper.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Container movements, split into the server's one-direction records.
///
/// A local movement holds both the delivered and the returned quantity; the
/// server takes one record per direction. The delivery travels under the
/// movement's own uuid and the return under a uuid derived from it, so a
/// retry sends the very same uuids.
class ContainerMovementPusher implements EntityPusher {
  ContainerMovementPusher(this._db, {DateTime Function()? today})
    : _today = today ?? DateTime.now;

  static const missing = 'El movimiento de envases ya no existe.';
  static const empty = 'El movimiento de envases no tiene cantidad.';
  static String unknownType(String code) =>
      'Tipo de envase desconocido: $code. Sincronizá el catálogo primero.';

  final AppDatabase _db;
  final DateTime Function() _today;

  @override
  PendingEntity get entity => PendingEntity.containerMovement;

  @override
  String get wireKey => 'container_movements';

  /// Client uuid of the return half of [movementId].
  static String returnUuid(String movementId) =>
      const Uuid().v5(Namespace.url.value, 'container-return/$movementId');

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final idsByMovement = <String, List<int>>{};
    for (final c in changes) {
      idsByMovement.putIfAbsent(c.entityId, () => []).add(c.id);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    for (final MapEntry(key: movementId, value: ids) in idsByMovement.entries) {
      final movement =
          await (_db.select(_db.containerMovementTable)
                ..where((t) => t.containerMovementId.equals(movementId)))
              .getSingleOrNull();
      if (movement == null) {
        rejections.add(LocalRejection(ids, missing));
        continue;
      }
      // Its visit is still open: it waits so it travels linked to it.
      if (await awaitsOpenVisit(_db, movement.visitId, today: _today())) {
        continue;
      }
      final type = await (_db.select(
        _db.containerTypeTable,
      )..where((t) => t.code.equals(movement.containerType))).getSingleOrNull();
      if (type == null) {
        rejections.add(
          LocalRejection(ids, unknownType(movement.containerType)),
        );
        continue;
      }
      if (movement.deliveredQuantity <= 0 && movement.returnedQuantity <= 0) {
        rejections.add(LocalRejection(ids, empty));
        continue;
      }

      final common = await _common(movement, type.id);
      Json half(String uuid, String movementType, int quantity) => {
        'uuid': uuid,
        ...common,
        'movement_type': movementType,
        'quantity': quantity,
      };
      if (movement.deliveredQuantity > 0) {
        records.add(
          PushRecord(
            uuid: movementId,
            changeIds: ids,
            body: half(movementId, 'DELIVERED', movement.deliveredQuantity),
          ),
        );
      }
      if (movement.returnedQuantity > 0) {
        final uuid = returnUuid(movementId);
        records.add(
          PushRecord(
            uuid: uuid,
            localId: movementId,
            changeIds: ids,
            body: half(uuid, 'RETURNED', movement.returnedQuantity),
          ),
        );
      }
    }
    return PushPlan(records: records, rejections: rejections);
  }

  /// The local row keeps one server id: the delivery's, or the return's
  /// when the movement only returned containers.
  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    final isReturn = record.uuid != record.localId;
    final query = _db.update(_db.containerMovementTable)
      ..where(
        (t) =>
            t.containerMovementId.equals(record.localId) &
            (isReturn ? t.serverId.isNull() : const Constant(true)),
      );
    await query.write(
      ContainerMovementTableCompanion(serverId: Value(serverId)),
    );
  }

  Future<Json> _common(ContainerMovementTableData movement, int typeId) async {
    final customer =
        await (_db.select(_db.customerTable)
              ..where((t) => t.customerId.equals(movement.customerId)))
            .getSingleOrNull();
    final visit = await resolveVisit(_db, movement.visitId);
    return {
      ...reference(
        'customer',
        serverId: customer?.serverId,
        uuid: movement.customerId,
      ),
      if (visit != null)
        ...reference('visit', serverId: visit.serverId, uuid: visit.visitId),
      'container_type_id': typeId,
    };
  }
}
