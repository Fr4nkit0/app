import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/route/data/repositories/repositories/drift_route_repository.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/visits/data/repositories/drift_visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';

/// Every repository writes its record and its pending change together, and
/// every local edit stamps the record's last modification date.
void main() {
  late AppDatabase db;
  late PendingChangeRepository queue;

  final longAgo = DateTime(2020, 1, 1);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = DriftPendingChangeRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Customer makeCustomer({String id = 'cust-1', String name = 'Carlos Gomez'}) =>
      Customer(
        id: id,
        name: name,
        phone: '11223344',
        addresses: [
          CustomerAddress(id: 'addr-1', street: 'Av. Belgrano 1200'),
        ],
        preferences: const [],
      );

  group('customers', () {
    late DriftCustomerRepository sut;

    setUp(() => sut = DriftCustomerRepository(db));

    test('creating a customer queues an insert', () async {
      await sut.saveCustomer(makeCustomer());

      final change = (await queue.getPending()).single;
      expect(change.entity, PendingEntity.customer);
      expect(change.entityId, 'cust-1');
      expect(change.action, PendingAction.insert);
      expect(change.payload?['name'], 'Carlos Gomez');
    });

    test('saving an existing customer queues an update', () async {
      await sut.saveCustomer(makeCustomer());
      await sut.saveCustomer(makeCustomer(name: 'Carlos G.'));

      final actions = (await queue.getPending()).map((c) => c.action);
      expect(actions, [PendingAction.insert, PendingAction.update]);
    });

    test('editing a customer queues an update with the new data', () async {
      await sut.saveCustomer(makeCustomer());

      await sut.updateCustomer(makeCustomer(name: 'Carlos Edited'));

      final change = (await queue.getPending()).last;
      expect(change.action, PendingAction.update);
      expect(change.entityId, 'cust-1');
      expect(change.payload?['name'], 'Carlos Edited');
    });

    test('editing a customer stamps its last modification date', () async {
      await sut.saveCustomer(makeCustomer());
      await (db.update(db.customerTable)).write(
        CustomerTableCompanion(lastModifiedDate: drift.Value(longAgo)),
      );

      await sut.updateCustomer(makeCustomer(name: 'Carlos Edited'));

      final row = await db.select(db.customerTable).getSingle();
      expect(row.lastModifiedDate.isAfter(longAgo), isTrue);
    });

    test('deleting a customer queues a delete', () async {
      await sut.saveCustomer(makeCustomer());

      await sut.deleteCustomer('cust-1');

      final change = (await queue.getPending()).last;
      expect(change.action, PendingAction.delete);
      expect(change.entityId, 'cust-1');
    });

    test('a failed edit of a missing customer queues nothing', () async {
      await sut.updateCustomer(makeCustomer(id: 'ghost'));

      expect(await queue.getPending(), isEmpty);
    });

    test('geocoding an address queues a customer update and stamps it', () async {
      await sut.saveCustomer(makeCustomer());
      await (db.update(db.customerAddressTable)).write(
        CustomerAddressTableCompanion(lastModifiedDate: drift.Value(longAgo)),
      );

      await sut.updateAddressCoordinates('addr-1', -24.78, -65.41);

      final change = (await queue.getPending()).last;
      expect(change.entity, PendingEntity.customer);
      expect(change.entityId, 'cust-1');
      expect(change.action, PendingAction.update);
      final row = await db.select(db.customerAddressTable).getSingle();
      expect(row.lastModifiedDate.isAfter(longAgo), isTrue);
    });

    test('geocoding a missing address queues nothing', () async {
      await sut.updateAddressCoordinates('ghost', 1, 2);

      expect(await queue.getPending(), isEmpty);
    });
  });

  group('route stops', () {
    Future<void> insertStop() async {
      await db
          .into(db.routeStopTable)
          .insert(
            RouteStopTableCompanion.insert(
              routeStopId: const drift.Value('stop-1'),
              routeId: 'route-1',
              customerId: 'cust-1',
              sequence: 1,
              scheduledAt: DateTime(2026, 1, 1, 9),
              lastModifiedDate: drift.Value(longAgo),
            ),
          );
    }

    test('changing a stop queues an update and stamps it', () async {
      await insertStop();

      await DriftRouteRepository(db).markStop('stop-1', StopStatus.done);

      final change = (await queue.getPending()).single;
      expect(change.entity, PendingEntity.routeStop);
      expect(change.entityId, 'stop-1');
      expect(change.action, PendingAction.update);
      expect(change.payload?['status'], 'done');
      final row = await db.select(db.routeStopTable).getSingle();
      expect(row.lastModifiedDate.isAfter(longAgo), isTrue);
    });
  });

  group('visits', () {
    test('recording a visit queues an insert', () async {
      await DriftVisitRepository(db).recordVisit(
        Visit(
          visitId: 'visit-1',
          routeStopId: 'stop-1',
          customerId: 'cust-1',
          visitType: VisitType.visit,
          outcome: 'absent',
          arrivedAt: DateTime(2026, 1, 1, 10),
        ),
      );

      final change = (await queue.getPending()).single;
      expect(change.entity, PendingEntity.visit);
      expect(change.entityId, 'visit-1');
      expect(change.action, PendingAction.insert);
      expect(change.payload?['outcome'], 'absent');
    });
  });

  group('sales', () {
    Sale makeSale(String id, PaymentMethod method) => Sale(
      id: id,
      customer: makeCustomer(),
      items: [
        SaleItem(
          product: const Product(
            id: 'prod-1',
            name: 'Bidon 20L',
            unitLabel: 'u',
            price: 100,
            available: 10,
          ),
          quantity: 2,
        ),
      ],
      total: 200,
      paymentMethod: method,
      date: DateTime(2026, 1, 1, 11),
    );

    test('saving a sale queues an insert with its items', () async {
      await DriftSaleRepository(db).saveSale(makeSale('sale-1', PaymentMethod.cash));

      final change = (await queue.getPending()).single;
      expect(change.entity, PendingEntity.sale);
      expect(change.entityId, 'sale-1');
      expect(change.action, PendingAction.insert);
      expect((change.payload?['items'] as List).length, 1);
    });

    test('a failed sale leaves nothing in the queue', () async {
      final sut = DriftSaleRepository(db);
      await sut.saveSale(makeSale('sale-dupe', PaymentMethod.cash));
      await queue.markSent([(await queue.getPending()).single.id]);

      await sut.saveSale(makeSale('sale-dupe', PaymentMethod.cash));

      expect(await queue.getPending(), isEmpty);
    });

    test('a credit sale stamps the customer balance it edits', () async {
      await db
          .into(db.customerBalanceTable)
          .insert(
            CustomerBalanceTableCompanion.insert(
              customerId: 'cust-1',
              currentBalance: const drift.Value(50),
              lastModifiedDate: drift.Value(longAgo),
            ),
          );

      await DriftSaleRepository(db).saveSale(makeSale('sale-2', PaymentMethod.credit));

      final row = await db.select(db.customerBalanceTable).getSingle();
      expect(row.currentBalance, 250);
      expect(row.lastModifiedDate.isAfter(longAgo), isTrue);
    });
  });

  group('inventory', () {
    test('returning route stock stamps the load it edits', () async {
      await db
          .into(db.routeInventoryLoadTable)
          .insert(
            RouteInventoryLoadTableCompanion.insert(
              routeInventoryLoadId: const drift.Value('load-1'),
              routeId: 'route-1',
              productId: 'prod-1',
              quantity: 10,
              lastModifiedDate: drift.Value(longAgo),
            ),
          );

      await DriftInventoryRepository(db).recordRouteReturn('load-1', 3);

      final row = await db.select(db.routeInventoryLoadTable).getSingle();
      expect(row.quantity, 7);
      expect(row.lastModifiedDate.isAfter(longAgo), isTrue);
    });
  });
}
