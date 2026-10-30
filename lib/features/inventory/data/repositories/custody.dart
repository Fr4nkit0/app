import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// The containers of each type a customer holds: the custody downloaded
/// from the server plus the container movements not yet sent.
///
/// The only module that writes custody. Every local container movement is
/// posted at once, and every download reconciles it with the server's
/// value, the same rule as the customer account (ADR 0003).
class Custody {
  Custody(this._db);

  final AppDatabase _db;

  /// Moves the custody of [containerType] held by [customerId] by [delta]
  /// (positive: holds more).
  Future<void> post(String customerId, String containerType, int delta) async {
    final existing = await (_db.select(
      _db.customerContainerBalanceTable,
    )..where((t) => _of(t, customerId, containerType))).getSingleOrNull();
    if (existing == null) {
      await _db
          .into(_db.customerContainerBalanceTable)
          .insert(
            CustomerContainerBalanceTableCompanion.insert(
              customerId: customerId,
              containerType: containerType,
              quantity: Value(delta),
            ),
          );
      return;
    }
    await (_db.update(
      _db.customerContainerBalanceTable,
    )..where((t) => _of(t, customerId, containerType))).write(
      CustomerContainerBalanceTableCompanion(
        quantity: Value(existing.quantity + delta),
        lastModifiedDate: Value(DateTime.now()),
      ),
    );
  }

  /// The custody of [customerId], one balance per container code.
  Stream<List<CustomerContainerBalance>> watch(String customerId) {
    return (_db.select(
      _db.customerContainerBalanceTable,
    )..where((t) => t.customerId.equals(customerId))).watch().map(
      (rows) => [
        for (final row in rows)
          CustomerContainerBalance(
            customerId: row.customerId,
            containerType: row.containerType,
            quantity: row.quantity,
          ),
      ],
    );
  }

  /// Delivered minus returned containers of [containerType] in the
  /// movements of [customerId] the server has not received yet, and in the
  /// local reversals of the sales whose cancellation it has not received.
  Future<int> pendingMovements(String customerId, String containerType) async {
    String pendingIds(int entity) =>
        '(SELECT entity_id FROM pending_changes '
        'WHERE entity = ?$entity AND status = ?4)';
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(m.delivered_quantity - m.returned_quantity), 0) '
          'AS delta FROM container_movements m '
          'WHERE m.customer_id = ?1 AND m.container_type = ?2 '
          'AND (m.container_movement_id IN ${pendingIds(3)} '
          ' OR (m.reverses_movement_id IS NOT NULL AND m.server_id IS NULL '
          '  AND m.sale_id IN ${pendingIds(5)}))',
          variables: [
            Variable.withString(customerId),
            Variable.withString(containerType),
            Variable.withString(PendingEntity.containerMovement.wireName),
            Variable.withString(PendingStatus.pending.wireName),
            Variable.withString(PendingEntity.saleCancellation.wireName),
          ],
          readsFrom: {_db.containerMovementTable, _db.pendingChangeTable},
        )
        .getSingle();
    return row.read<int>('delta');
  }

  /// Stores the custody the server computed for [customerId] and
  /// [containerType], plus the movements the server has not received yet.
  Future<void> reconcile(
    String customerId,
    String containerType,
    int serverBalance, {
    int? serverId,
    Value<bool> enabled = const Value.absent(),
  }) async {
    final pending = await pendingMovements(customerId, containerType);
    await _db
        .into(_db.customerContainerBalanceTable)
        .insertOnConflictUpdate(
          CustomerContainerBalanceTableCompanion.insert(
            customerId: customerId,
            containerType: containerType,
            quantity: Value(serverBalance + pending),
            enabled: enabled,
            serverId: serverId == null ? const Value.absent() : Value(serverId),
          ),
        );
  }

  /// The reversals the device wrote when it cancelled the sale [saleId]
  /// (see `InventoryRepository.reverseSaleMovements`): no server id yet,
  /// since the server writes its own.
  static Expression<bool> isLocalReversalOf(
    $ContainerMovementTableTable t,
    String saleId,
  ) =>
      t.saleId.equals(saleId) &
      t.reversesMovementId.isNotNull() &
      t.serverId.isNull();

  static Expression<bool> _of(
    $CustomerContainerBalanceTableTable t,
    String customerId,
    String containerType,
  ) => t.customerId.equals(customerId) & t.containerType.equals(containerType);
}
