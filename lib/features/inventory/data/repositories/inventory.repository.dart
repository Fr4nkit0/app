import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/inventory/data/repositories/custody.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/domain/models/route_inventory_load.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

abstract class InventoryRepository {
  Future<void> recordContainerMovement(ContainerMovement movement);

  /// Takes the movements recorded with the sale [saleId] back out of
  /// custody, as the server does when the sale is cancelled; run it inside
  /// the use case's unit of work.
  Future<void> reverseSaleMovements(String saleId, {required DateTime at});

  Stream<List<CustomerContainerBalance>> watchContainerBalances(
    String customerId,
  );

  /// The movements recorded in the visit [visitId], without the reversals
  /// of its cancelled sales.
  Future<List<ContainerMovement>> getVisitMovements(String visitId);
  Future<void> loadRouteInventory(RouteInventoryLoad load);
  Future<void> recordRouteReturn(
    String routeInventoryLoadId,
    int returnedQuantity,
  );
  Future<List<RouteInventoryLoad>> getRouteLoads(String routeId);

  /// Enabled container types of the catalog, ordered by id.
  Stream<List<ContainerType>> watchContainerTypes();
}

class DriftInventoryRepository implements InventoryRepository {
  DriftInventoryRepository(AppDatabase db)
    : _db = db,
      _queue = DriftPendingChangeRepository(db),
      _custody = Custody(db);

  final AppDatabase _db;
  final PendingChangeRepository _queue;
  final Custody _custody;

  @override
  Future<void> recordContainerMovement(ContainerMovement movement) async {
    await _db
        .into(_db.containerMovementTable)
        .insert(
          ContainerMovementTableCompanion.insert(
            containerMovementId: Value(movement.id),
            customerId: movement.customerId,
            containerType: movement.containerType,
            deliveredQuantity: movement.deliveredQuantity,
            returnedQuantity: movement.returnedQuantity,
            createdAt: Value(movement.createdAt),
            visitId: Value(movement.visitId),
            routeId: Value(movement.routeId),
            saleId: Value(movement.saleId),
          ),
        );

    await _custody.post(
      movement.customerId,
      movement.containerType,
      movement.netQuantity,
    );

    await _queue.enqueue(
      entity: PendingEntity.containerMovement,
      entityId: movement.id,
      action: PendingAction.insert,
      payload: {
        'containerMovementId': movement.id,
        'customerId': movement.customerId,
        'containerType': movement.containerType,
        'deliveredQuantity': movement.deliveredQuantity,
        'returnedQuantity': movement.returnedQuantity,
        'visitId': movement.visitId,
        'routeId': movement.routeId,
        'saleId': movement.saleId,
        'createdAt': movement.createdAt.toIso8601String(),
      },
    );
  }

  /// Each movement of the sale gets a local reversal dated [at]: a row that
  /// undoes its quantities and points at it, posted to custody and never
  /// queued, since the server writes its own reversal when it takes the
  /// cancellation. The bootstrap links the server's reversals to this row
  /// instead of storing them again. A movement already reversed is skipped.
  @override
  Future<void> reverseSaleMovements(
    String saleId, {
    required DateTime at,
  }) async {
    final movements =
        await (_db.select(_db.containerMovementTable)..where(
              (t) => t.saleId.equals(saleId) & t.reversesMovementId.isNull(),
            ))
            .get();
    for (final movement in movements) {
      final reversed =
          await (_db.select(_db.containerMovementTable)
                ..where(
                  (t) =>
                      t.reversesMovementId.equals(movement.containerMovementId),
                )
                ..limit(1))
              .getSingleOrNull();
      if (reversed != null) continue;
      await _db
          .into(_db.containerMovementTable)
          .insert(
            ContainerMovementTableCompanion.insert(
              containerMovementId: Value(const Uuid().v4()),
              customerId: movement.customerId,
              containerType: movement.containerType,
              deliveredQuantity: -movement.deliveredQuantity,
              returnedQuantity: -movement.returnedQuantity,
              createdAt: Value(at),
              visitId: Value(movement.visitId),
              routeId: Value(movement.routeId),
              saleId: Value(saleId),
              reversesMovementId: Value(movement.containerMovementId),
            ),
          );
      await _custody.post(
        movement.customerId,
        movement.containerType,
        movement.returnedQuantity - movement.deliveredQuantity,
      );
    }
  }

  /// Takes back the local reversals of the sale [saleId] when the server
  /// refused its cancellation: its containers count in custody again.
  Future<void> undoSaleReversal(String saleId) async {
    final reversals = await (_db.select(
      _db.containerMovementTable,
    )..where((t) => Custody.isLocalReversalOf(t, saleId))).get();
    for (final reversal in reversals) {
      await _custody.post(
        reversal.customerId,
        reversal.containerType,
        reversal.returnedQuantity - reversal.deliveredQuantity,
      );
    }
    await (_db.delete(
      _db.containerMovementTable,
    )..where((t) => Custody.isLocalReversalOf(t, saleId))).go();
  }

  @override
  Stream<List<CustomerContainerBalance>> watchContainerBalances(
    String customerId,
  ) {
    return _custody.watch(customerId);
  }

  @override
  Future<List<ContainerMovement>> getVisitMovements(String visitId) async {
    final rows =
        await (_db.select(_db.containerMovementTable)..where(
              (t) => t.visitId.equals(visitId) & t.reversesMovementId.isNull(),
            ))
            .get();
    return rows.map(_rowToMovement).toList();
  }

  @override
  Future<void> loadRouteInventory(RouteInventoryLoad load) async {
    await _db
        .into(_db.routeInventoryLoadTable)
        .insert(
          RouteInventoryLoadTableCompanion.insert(
            routeInventoryLoadId: Value(load.id),
            routeId: load.routeId,
            productId: load.productId,
            quantity: load.quantity,
            loadedAt: Value(load.loadedAt),
            createdBy: Value(load.createdBy),
          ),
        );
  }

  @override
  Future<void> recordRouteReturn(
    String routeInventoryLoadId,
    int returnedQuantity,
  ) async {
    final existing =
        await (_db.select(_db.routeInventoryLoadTable)..where(
              (t) => t.routeInventoryLoadId.equals(routeInventoryLoadId),
            ))
            .getSingleOrNull();

    if (existing == null) return;

    await (_db.update(
      _db.routeInventoryLoadTable,
    )..where((t) => t.routeInventoryLoadId.equals(routeInventoryLoadId))).write(
      RouteInventoryLoadTableCompanion(
        quantity: Value(existing.quantity - returnedQuantity),
        lastModifiedDate: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<List<RouteInventoryLoad>> getRouteLoads(String routeId) async {
    final rows =
        await (_db.select(_db.routeInventoryLoadTable)
              ..where((t) => t.routeId.equals(routeId) & t.enabled.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.loadedAt)]))
            .get();
    return rows.map(_rowToLoad).toList();
  }

  @override
  Stream<List<ContainerType>> watchContainerTypes() {
    // Re-emits when the catalog or the products that use it change.
    final changes = _db
        .customSelect(
          'SELECT 1',
          readsFrom: {_db.containerTypeTable, _db.productTable},
        )
        .watch();
    return changes.asyncMap((_) async {
      final rows =
          await (_db.select(_db.containerTypeTable)
                ..where((t) => t.enabled.equals(true))
                ..orderBy([(t) => OrderingTerm.asc(t.id)]))
              .get();
      final products =
          await (_db.select(_db.productTable)..where(
                (t) => t.enabled.equals(true) & t.containerTypeId.isNotNull(),
              ))
              .get();
      final productNames = <int, List<String>>{};
      for (final p in products) {
        productNames.putIfAbsent(p.containerTypeId!, () => []).add(p.name);
      }
      return [
        for (final row in rows)
          ContainerType.fromCatalog(
            id: row.id,
            code: row.code,
            description: row.description,
            productName: _singleName(productNames[row.id]),
          ),
      ];
    });
  }

  /// The name of the only enabled product that uses a type; null when no
  /// product or several products share it.
  static String? _singleName(List<String>? names) =>
      names != null && names.length == 1 ? names.single : null;

  ContainerMovement _rowToMovement(ContainerMovementTableData row) =>
      ContainerMovement(
        id: row.containerMovementId,
        customerId: row.customerId,
        containerType: row.containerType,
        deliveredQuantity: row.deliveredQuantity,
        returnedQuantity: row.returnedQuantity,
        createdAt: row.createdAt,
        visitId: row.visitId,
        routeId: row.routeId,
        saleId: row.saleId,
      );

  RouteInventoryLoad _rowToLoad(RouteInventoryLoadTableData row) =>
      RouteInventoryLoad(
        id: row.routeInventoryLoadId,
        routeId: row.routeId,
        productId: row.productId,
        quantity: row.quantity,
        loadedAt: row.loadedAt,
        createdBy: row.createdBy,
      );
}
