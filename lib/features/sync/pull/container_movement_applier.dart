import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database.helper.dart';
import '../push/container_movement_pusher.dart';
import 'pull_applier.dart';

/// Today's container movements, carried only by the bootstrap so a
/// reinstalled device rebuilds the day's work; the incremental pull does not
/// send them.
///
/// Rows are written directly, never through the inventory repository: the
/// downloaded custody already includes these movements, so they move no
/// custody and nothing is queued for push.
///
/// The server keeps one record per direction: a delivery fills the local
/// delivered quantity and a return the returned one. Other server movement
/// types have no local meaning and are skipped. A server reversal (no client
/// uuid) is stored as its own movement that takes the quantity of the
/// movement it reverses back out, so the visit's totals net to what the
/// server holds; custody stays the downloaded value either way. When the
/// device cancelled the sale itself it already wrote one local reversal for
/// both halves of the movement; the server's reversals are linked to it
/// instead, so the cancellation shows once.
class ContainerMovementApplier {
  ContainerMovementApplier(this._db);

  final AppDatabase _db;

  static const _delivered = 'DELIVERED';
  static const _returned = 'RETURNED';

  /// A movement already on the device (by server id, by client uuid, or as
  /// the return half of a local movement) is linked to its server id and
  /// sale. When that row is still missing this half's quantity (a reinstalled
  /// device rebuilt it from the other half), the quantity is filled in; a row
  /// with unsent changes keeps its local values. One whose customer, container type or reversed movement the
  /// download did not carry is dropped.
  Future<void> storeToday(List<Json> movements, PullContext context) async {
    final typeOf = {
      for (final m in movements) m['id'] as int: m['movement_type'] as String?,
    };
    // Originals first, so a reversal finds the movement it undoes.
    final ordered = [
      ...movements.where((m) => m['reverses_movement_id'] == null),
      ...movements.where((m) => m['reverses_movement_id'] != null),
    ];
    for (final m in ordered) {
      final serverId = m['id'] as int;
      final reverses = m['reverses_movement_id'] as int?;
      // A reversal undoes its original's direction, whatever its own type.
      final side = typeOf[reverses ?? serverId];
      if (side != _delivered && side != _returned) continue;
      final customerId = await context.ids.customer(m['customer_id'] as int?);
      final code = await context.ids.containerType(
        m['container_type_id'] as int?,
      );
      final reversedId = await context.ids.movement(reverses);
      if (customerId == null || code == null) continue;
      if (reverses != null && reversedId == null) continue;
      final clientUuid = m['client_uuid'] as String?;
      final saleId = await context.ids.sale(m['sale_id'] as int?);

      final existing = reversedId == null
          ? await _existing(serverId, clientUuid, customerId)
          : await _existingReversal(serverId, reversedId, side!);
      if (existing != null) {
        // Like the push: the row keeps its delivery's server id, or its
        // return's when it only returned containers.
        final keepsServerId = side == _delivered || existing.serverId == null;
        final quantity = reversedId == null
            ? _missingHalf(existing, side!, m, context)
            : null;
        await (_db.update(_db.containerMovementTable)..where(
              (t) => t.containerMovementId.equals(existing.containerMovementId),
            ))
            .write(
              ContainerMovementTableCompanion(
                serverId: keepsServerId
                    ? Value(serverId)
                    : const Value.absent(),
                saleId: existing.saleId == null && saleId != null
                    ? Value(saleId)
                    : const Value.absent(),
                deliveredQuantity: side == _delivered && quantity != null
                    ? Value(quantity)
                    : const Value.absent(),
                returnedQuantity: side == _returned && quantity != null
                    ? Value(quantity)
                    : const Value.absent(),
              ),
            );
        context.ids.recordMovement(serverId, existing.containerMovementId);
        continue;
      }

      final quantity =
          (m['quantity'] as num).toInt() * (reverses == null ? 1 : -1);
      final stopId = await context.ids.stopOfVisit(m['visit_id'] as int?);
      final movementId = clientUuid ?? const Uuid().v4();
      await _db
          .into(_db.containerMovementTable)
          .insert(
            ContainerMovementTableCompanion.insert(
              containerMovementId: Value(movementId),
              customerId: customerId,
              containerType: code,
              deliveredQuantity: side == _delivered ? quantity : 0,
              returnedQuantity: side == _returned ? quantity : 0,
              visitId: Value(stopId),
              routeId: Value(await _routeOfStop(stopId)),
              saleId: Value(saleId),
              reversesMovementId: Value(reversedId),
              serverId: Value(serverId),
              createdAt: Value(
                DateTime.parse(m['created_at'] as String).toLocal(),
              ),
            ),
          );
      context.ids.recordMovement(serverId, movementId);
    }
  }

  /// The quantity of [movement]'s [side] when [existing] lacks it: the other
  /// half of the same local movement rebuilt it first. A reversal row, a row
  /// with unsent changes or one that already holds this side is left as is.
  int? _missingHalf(
    ContainerMovementTableData existing,
    String side,
    Json movement,
    PullContext context,
  ) {
    if (existing.reversesMovementId != null) return null;
    if (context.unsent.movements.contains(existing.containerMovementId)) {
      return null;
    }
    final held = side == _delivered
        ? existing.deliveredQuantity
        : existing.returnedQuantity;
    return held == 0 ? (movement['quantity'] as num).toInt() : null;
  }

  Future<ContainerMovementTableData?> _existing(
    int serverId,
    String? clientUuid,
    String customerId,
  ) async {
    final direct =
        await (_db.select(_db.containerMovementTable)
              ..where(
                (t) =>
                    t.serverId.equals(serverId) |
                    (clientUuid == null
                        ? const Constant(false)
                        : t.containerMovementId.equals(clientUuid)),
              )
              ..limit(1))
            .getSingleOrNull();
    if (direct != null || clientUuid == null) return direct;
    // The return half travels under a uuid derived from the local movement.
    final ofCustomer = await (_db.select(
      _db.containerMovementTable,
    )..where((t) => t.customerId.equals(customerId))).get();
    for (final local in ofCustomer) {
      if (ContainerMovementPusher.returnUuid(local.containerMovementId) ==
          clientUuid) {
        return local;
      }
    }
    return null;
  }

  /// The reversal of [reversedId] already on the device that undoes its
  /// [side]: one stored by an earlier download, or the device's own, which
  /// undoes both sides at once.
  Future<ContainerMovementTableData?> _existingReversal(
    int serverId,
    String reversedId,
    String side,
  ) async {
    final reversals = await (_db.select(
      _db.containerMovementTable,
    )..where((t) => t.reversesMovementId.equals(reversedId))).get();
    for (final reversal in reversals) {
      if (reversal.serverId == serverId) return reversal;
    }
    for (final reversal in reversals) {
      final undone = side == _delivered
          ? reversal.deliveredQuantity
          : reversal.returnedQuantity;
      if (undone != 0) return reversal;
    }
    return null;
  }

  Future<String?> _routeOfStop(String? stopId) async {
    if (stopId == null) return null;
    return (await (_db.select(
      _db.routeStopTable,
    )..where((t) => t.routeStopId.equals(stopId))).getSingleOrNull())?.routeId;
  }
}
