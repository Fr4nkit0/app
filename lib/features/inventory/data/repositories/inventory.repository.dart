import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/domain/models/route_inventory_load.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

abstract class InventoryRepository {
  Future<void> recordContainerMovement(ContainerMovement movement);
  Stream<List<CustomerContainerBalance>> watchContainerBalances(
    String customerId,
  );
  Future<List<ContainerMovement>> getVisitMovements(String visitId);
  Future<void> loadRouteInventory(RouteInventoryLoad load);
  Future<void> recordRouteReturn(
    String routeInventoryLoadId,
    int returnedQuantity,
  );
  Future<List<RouteInventoryLoad>> getRouteLoads(String routeId);
}

class DriftInventoryRepository implements InventoryRepository {
  DriftInventoryRepository(AppDatabase db)
    : _db = db,
      _queue = DriftPendingChangeRepository(db);

  final AppDatabase _db;
  final PendingChangeRepository _queue;

  @override
  Future<void> recordContainerMovement(ContainerMovement movement) async {
    await _db.transaction(() async {
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
            ),
          );

      final existing =
          await (_db.select(_db.customerContainerBalanceTable)..where(
                (t) =>
                    t.customerId.equals(movement.customerId) &
                    t.containerType.equals(movement.containerType),
              ))
              .getSingleOrNull();

      final newQty = (existing?.quantity ?? 0) + movement.netQuantity;

      if (existing == null) {
        await _db
            .into(_db.customerContainerBalanceTable)
            .insert(
              CustomerContainerBalanceTableCompanion.insert(
                customerId: movement.customerId,
                containerType: movement.containerType,
                quantity: Value(newQty),
              ),
            );
      } else {
        await (_db.update(_db.customerContainerBalanceTable)..where(
              (t) =>
                  t.customerId.equals(movement.customerId) &
                  t.containerType.equals(movement.containerType),
            ))
            .write(
              CustomerContainerBalanceTableCompanion(
                quantity: Value(newQty),
                lastModifiedDate: Value(DateTime.now()),
              ),
            );
      }

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
          'createdAt': movement.createdAt.toIso8601String(),
        },
      );
    });
  }

  @override
  Stream<List<CustomerContainerBalance>> watchContainerBalances(
    String customerId,
  ) {
    return (_db.select(_db.customerContainerBalanceTable)
          ..where((t) => t.customerId.equals(customerId)))
        .watch()
        .map((rows) => rows.map(_rowToBalance).toList());
  }

  @override
  Future<List<ContainerMovement>> getVisitMovements(String visitId) async {
    final rows = await (_db.select(
      _db.containerMovementTable,
    )..where((t) => t.visitId.equals(visitId))).get();
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
              ..where((t) => t.routeId.equals(routeId))
              ..orderBy([(t) => OrderingTerm.asc(t.loadedAt)]))
            .get();
    return rows.map(_rowToLoad).toList();
  }

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
      );

  CustomerContainerBalance _rowToBalance(
    CustomerContainerBalanceTableData row,
  ) => CustomerContainerBalance(
    customerId: row.customerId,
    containerType: row.containerType,
    quantity: row.quantity,
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
