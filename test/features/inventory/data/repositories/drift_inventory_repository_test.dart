import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/models/route_inventory_load.dart';

void main() {
  late AppDatabase db;
  late DriftInventoryRepository sut;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftInventoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  ContainerMovement makeMovement({
    String id = 'mov-1',
    String customerId = 'mock-customer-1',
    String containerType = 'BIDON_20L',
    int delivered = 3,
    int returned = 1,
    String? visitId,
    DateTime? createdAt,
  }) {
    return ContainerMovement(
      id: id,
      customerId: customerId,
      containerType: containerType,
      deliveredQuantity: delivered,
      returnedQuantity: returned,
      createdAt: createdAt ?? DateTime.now(),
      visitId: visitId,
    );
  }

  RouteInventoryLoad makeLoad({
    String id = 'load-1',
    String routeId = 'route-fake-1',
    String productId = 'product-fake-1',
    int quantity = 50,
    DateTime? loadedAt,
  }) {
    return RouteInventoryLoad(
      id: id,
      routeId: routeId,
      productId: productId,
      quantity: quantity,
      loadedAt: loadedAt ?? DateTime.now(),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // recordContainerMovement
  // ──────────────────────────────────────────────────────────────────────────

  group('recordContainerMovement', () {
    test('inserts movement row with correct fields', () async {
      await sut.recordContainerMovement(
        makeMovement(delivered: 4, returned: 2),
      );

      final rows = await db.select(db.containerMovementTable).get();
      expect(rows.length, 1);
      expect(rows.first.containerMovementId, 'mov-1');
      expect(rows.first.customerId, 'mock-customer-1');
      expect(rows.first.containerType, 'BIDON_20L');
      expect(rows.first.deliveredQuantity, 4);
      expect(rows.first.returnedQuantity, 2);
    });

    test('creates balance row on first movement with net quantity', () async {
      await sut.recordContainerMovement(
        makeMovement(delivered: 5, returned: 2),
      );

      final rows = await db.select(db.customerContainerBalanceTable).get();
      expect(rows.length, 1);
      expect(rows.first.quantity, 3); // net = 5 - 2
    });

    test('updates existing balance on subsequent movements', () async {
      await sut.recordContainerMovement(
        makeMovement(id: 'mov-1', delivered: 5, returned: 1),
      );
      await sut.recordContainerMovement(
        makeMovement(id: 'mov-2', delivered: 2, returned: 3),
      );

      final rows = await db.select(db.customerContainerBalanceTable).get();
      expect(rows.length, 1);
      expect(rows.first.quantity, 3); // (5-1) + (2-3) = 4 + (-1) = 3
    });

    test('handles pure return movement (delivered = 0)', () async {
      await sut.recordContainerMovement(
        makeMovement(id: 'mov-1', delivered: 4, returned: 0),
      );
      await sut.recordContainerMovement(
        makeMovement(id: 'mov-2', delivered: 0, returned: 3),
      );

      final rows = await db.select(db.customerContainerBalanceTable).get();
      expect(rows.first.quantity, 1); // 4 - 3 = 1
    });

    test('tracks balances independently per container type', () async {
      await sut.recordContainerMovement(
        makeMovement(
          id: 'mov-1',
          containerType: 'BIDON_20L',
          delivered: 3,
          returned: 0,
        ),
      );
      await sut.recordContainerMovement(
        makeMovement(
          id: 'mov-2',
          containerType: 'SIFON_2L',
          delivered: 10,
          returned: 2,
        ),
      );

      final rows = await db.select(db.customerContainerBalanceTable).get();
      expect(rows.length, 2);

      final bidon = rows.firstWhere((r) => r.containerType == 'BIDON_20L');
      final sifon = rows.firstWhere((r) => r.containerType == 'SIFON_2L');
      expect(bidon.quantity, 3);
      expect(sifon.quantity, 8);
    });

    test('tracks balances independently per customer', () async {
      await sut.recordContainerMovement(
        makeMovement(
          id: 'mov-1',
          customerId: 'mock-customer-1',
          delivered: 5,
          returned: 0,
        ),
      );
      await sut.recordContainerMovement(
        makeMovement(
          id: 'mov-2',
          customerId: 'mock-customer-2',
          delivered: 2,
          returned: 1,
        ),
      );

      final rows = await db.select(db.customerContainerBalanceTable).get();
      expect(rows.length, 2);

      final c1 = rows.firstWhere((r) => r.customerId == 'mock-customer-1');
      final c2 = rows.firstWhere((r) => r.customerId == 'mock-customer-2');
      expect(c1.quantity, 5);
      expect(c2.quantity, 1);
    });

    test('logs audit entry with correct fields', () async {
      await sut.recordContainerMovement(makeMovement(id: 'mov-audit'));

      final logs = await db.select(db.auditLogTable).get();
      expect(logs.length, 1);
      expect(logs.first.action, 'INSERT');
      expect(logs.first.tableNameColumn, 'container_movements');
      expect(logs.first.recordId, 'mov-audit');
      expect(logs.first.payload, isNotNull);
    });

    test(
      'rolls back all writes when movement insert fails (duplicate PK)',
      () async {
        await db
            .into(db.containerMovementTable)
            .insert(
              ContainerMovementTableCompanion.insert(
                containerMovementId: const drift.Value('mov-dupe'),
                customerId: 'mock-customer-1',
                containerType: 'BIDON_20L',
                deliveredQuantity: 1,
                returnedQuantity: 0,
              ),
            );

        await expectLater(
          sut.recordContainerMovement(
            makeMovement(id: 'mov-dupe', delivered: 99, returned: 0),
          ),
          throwsA(anything),
        );

        final balances = await db
            .select(db.customerContainerBalanceTable)
            .get();
        expect(balances, isEmpty);

        final logs = await db.select(db.auditLogTable).get();
        expect(logs, isEmpty);
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────────────
  // watchContainerBalances
  // ──────────────────────────────────────────────────────────────────────────

  group('watchContainerBalances', () {
    test('emits empty list when no balances exist', () async {
      final list = await sut.watchContainerBalances('mock-customer-1').first;
      expect(list, isEmpty);
    });

    test('emits updated list after recordContainerMovement', () async {
      final emissions = <List<dynamic>>[];
      final sub = sut
          .watchContainerBalances('mock-customer-1')
          .listen(emissions.add);
      addTearDown(sub.cancel);

      await Future.delayed(const Duration(milliseconds: 30));

      await sut.recordContainerMovement(
        makeMovement(containerType: 'BIDON_20L', delivered: 4, returned: 1),
      );

      await Future.delayed(const Duration(milliseconds: 30));

      expect(emissions.first, isEmpty);
      expect(emissions.last.length, 1);
      expect(emissions.last.first.quantity, 3);
    });

    test('returns only balances for the specified customer', () async {
      await sut.recordContainerMovement(
        makeMovement(id: 'mov-1', customerId: 'mock-customer-1'),
      );
      await sut.recordContainerMovement(
        makeMovement(id: 'mov-2', customerId: 'mock-customer-2'),
      );

      final list = await sut.watchContainerBalances('mock-customer-1').first;
      expect(list.length, 1);
      expect(list.first.customerId, 'mock-customer-1');
    });

    test('emits one entry per container type for the customer', () async {
      await sut.recordContainerMovement(
        makeMovement(
          id: 'mov-1',
          containerType: 'BIDON_20L',
          delivered: 3,
          returned: 0,
        ),
      );
      await sut.recordContainerMovement(
        makeMovement(
          id: 'mov-2',
          containerType: 'SIFON_2L',
          delivered: 5,
          returned: 2,
        ),
      );

      final list = await sut.watchContainerBalances('mock-customer-1').first;
      expect(list.length, 2);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // getVisitMovements
  // ──────────────────────────────────────────────────────────────────────────

  group('getVisitMovements', () {
    test('returns movements for the given visitId', () async {
      await sut.recordContainerMovement(
        makeMovement(id: 'mov-v1', visitId: 'visit-abc'),
      );
      await sut.recordContainerMovement(
        makeMovement(id: 'mov-v2', visitId: 'visit-xyz'),
      );

      final results = await sut.getVisitMovements('visit-abc');
      expect(results.length, 1);
      expect(results.first.id, 'mov-v1');
    });

    test('returns empty list for unknown visitId', () async {
      final results = await sut.getVisitMovements('visit-unknown');
      expect(results, isEmpty);
    });

    test('returns multiple movements for the same visit', () async {
      await sut.recordContainerMovement(
        makeMovement(
          id: 'mov-a',
          containerType: 'BIDON_20L',
          visitId: 'visit-1',
        ),
      );
      await sut.recordContainerMovement(
        makeMovement(
          id: 'mov-b',
          containerType: 'SIFON_2L',
          visitId: 'visit-1',
        ),
      );

      final results = await sut.getVisitMovements('visit-1');
      expect(results.length, 2);
    });

    test('movement domain model fields are mapped correctly', () async {
      await sut.recordContainerMovement(
        makeMovement(
          id: 'mov-map',
          containerType: 'SIFON_2L',
          delivered: 6,
          returned: 2,
          visitId: 'visit-map',
        ),
      );

      final results = await sut.getVisitMovements('visit-map');
      final m = results.first;
      expect(m.id, 'mov-map');
      expect(m.containerType, 'SIFON_2L');
      expect(m.deliveredQuantity, 6);
      expect(m.returnedQuantity, 2);
      expect(m.netQuantity, 4);
      expect(m.visitId, 'visit-map');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // loadRouteInventory
  // ──────────────────────────────────────────────────────────────────────────

  group('loadRouteInventory', () {
    test('inserts load record with correct fields', () async {
      final loadedAt = DateTime(2024, 6, 1, 8, 0);
      await sut.loadRouteInventory(
        makeLoad(
          id: 'load-1',
          routeId: 'route-r1',
          productId: 'product-p1',
          quantity: 100,
          loadedAt: loadedAt,
        ),
      );

      final rows = await db.select(db.routeInventoryLoadTable).get();
      expect(rows.length, 1);
      expect(rows.first.routeInventoryLoadId, 'load-1');
      expect(rows.first.routeId, 'route-r1');
      expect(rows.first.productId, 'product-p1');
      expect(rows.first.quantity, 100);
      expect(rows.first.loadedAt, loadedAt);
    });

    test('multiple loads for different products on same route', () async {
      await sut.loadRouteInventory(
        makeLoad(id: 'load-1', productId: 'prod-a', quantity: 50),
      );
      await sut.loadRouteInventory(
        makeLoad(id: 'load-2', productId: 'prod-b', quantity: 30),
      );

      final rows = await db.select(db.routeInventoryLoadTable).get();
      expect(rows.length, 2);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // recordRouteReturn
  // ──────────────────────────────────────────────────────────────────────────

  group('recordRouteReturn', () {
    test('decreases the quantity of the specified load', () async {
      await sut.loadRouteInventory(makeLoad(id: 'load-1', quantity: 50));
      await sut.recordRouteReturn('load-1', 12);

      final row = await db.select(db.routeInventoryLoadTable).getSingle();
      expect(row.quantity, 38);
    });

    test('decreases by the exact returned quantity', () async {
      await sut.loadRouteInventory(makeLoad(id: 'load-1', quantity: 100));
      await sut.recordRouteReturn('load-1', 100);

      final row = await db.select(db.routeInventoryLoadTable).getSingle();
      expect(row.quantity, 0);
    });

    test('does nothing when load id does not exist', () async {
      await sut.loadRouteInventory(makeLoad(id: 'load-1', quantity: 50));
      await sut.recordRouteReturn('load-nonexistent', 10);

      final row = await db.select(db.routeInventoryLoadTable).getSingle();
      expect(row.quantity, 50); // unchanged
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // getRouteLoads
  // ──────────────────────────────────────────────────────────────────────────

  group('getRouteLoads', () {
    test('returns loads for the given routeId', () async {
      await sut.loadRouteInventory(makeLoad(id: 'load-1', routeId: 'route-A'));
      await sut.loadRouteInventory(makeLoad(id: 'load-2', routeId: 'route-B'));

      final results = await sut.getRouteLoads('route-A');
      expect(results.length, 1);
      expect(results.first.id, 'load-1');
    });

    test('returns empty list for unknown routeId', () async {
      final results = await sut.getRouteLoads('route-unknown');
      expect(results, isEmpty);
    });

    test('returns loads ordered by loadedAt ascending', () async {
      final earlier = DateTime(2024, 1, 1, 7, 0);
      final later = DateTime(2024, 1, 1, 14, 0);

      await sut.loadRouteInventory(
        makeLoad(id: 'load-late', routeId: 'route-A', loadedAt: later),
      );
      await sut.loadRouteInventory(
        makeLoad(id: 'load-early', routeId: 'route-A', loadedAt: earlier),
      );

      final results = await sut.getRouteLoads('route-A');
      expect(results.first.id, 'load-early');
      expect(results.last.id, 'load-late');
    });

    test('load domain model fields are mapped correctly', () async {
      final loadedAt = DateTime(2024, 3, 15);
      await sut.loadRouteInventory(
        RouteInventoryLoad(
          id: 'load-map',
          routeId: 'route-r1',
          productId: 'prod-p1',
          quantity: 75,
          loadedAt: loadedAt,
          createdBy: 'driver-1',
        ),
      );

      final results = await sut.getRouteLoads('route-r1');
      final l = results.first;
      expect(l.id, 'load-map');
      expect(l.routeId, 'route-r1');
      expect(l.productId, 'prod-p1');
      expect(l.quantity, 75);
      expect(l.loadedAt, loadedAt);
      expect(l.createdBy, 'driver-1');
    });
  });
}
