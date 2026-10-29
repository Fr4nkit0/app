import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/products/data/repositories/drift.product.repository.dart';
import 'package:app/features/route/data/repositories/drift_route_repository.dart';
import 'package:app/features/visits/data/repositories/drift_visit.repository.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> _bootstrap() => {
  'data': {
    'route': {'id': 7, 'date': _today(), 'status': 'IN_PROGRESS'},
    'stops': [
      {
        'id': 71,
        'route_id': 7,
        'customer_id': 11,
        'address_id': 111,
        'scheduled_time': '09:30:00',
        'is_rescheduled_from': null,
        'status': 'PENDING',
      },
      {
        'id': 72,
        'route_id': 7,
        'customer_id': 12,
        'address_id': null,
        'scheduled_time': null,
        'is_rescheduled_from': null,
        'status': 'PENDING',
      },
    ],
    'truck_inventory': [
      {'id': 900, 'route_id': 7, 'product_id': 21, 'current_quantity': '20.00'},
    ],
    'customers': [
      {
        'id': 11,
        'client_uuid': 'cust-uuid-11',
        'name': 'Ana',
        'phone_number': '111',
        'addresses': [
          {'id': 111, 'customer_id': 11, 'street': 'Belgrano 340', 'is_primary': true},
        ],
        'preferences': [],
        'agreements': [],
        'balance': {'current_balance': '1500.50'},
        'container_balances': [
          {'id': 1300, 'container_type_id': 1, 'balance': 3},
        ],
      },
      {'id': 12, 'client_uuid': 'cust-uuid-12', 'name': 'Beto', 'phone_number': null},
    ],
    'products': [
      {'id': 21, 'name': 'Water 20L'},
      {'id': 22, 'name': 'Soda 2L'},
    ],
    'container_types': [
      {'id': 1, 'code': 'BIDON_20L', 'description': '20L'},
    ],
    'payment_methods': [
      {'id': 5, 'code': 'CASH', 'name': 'Cash'},
    ],
    'visit_outcomes': [
      {'id': 3, 'name': 'Absent', 'triggers_reschedule': true},
    ],
    'server_time': '2026-10-19T12:00:00+00:00',
  },
  'message': null,
};

const _entities = [
  'routes',
  'route_stops',
  'route_inventories',
  'customers',
  'customer_addresses',
  'customer_preferences',
  'customer_agreements',
  'customer_balances',
  'customer_container_balances',
  'products',
  'container_types',
  'payment_methods',
  'visit_outcomes',
];

/// One pull page shaped like the server's: every entity key present.
Map<String, dynamic> _page(
  Map<String, List<Map<String, dynamic>>> rows, {
  int page = 1,
  bool last = true,
  String until = '2026-10-19T13:00:00+00:00',
  String cursor = '2026-10-19T12:59:55+00:00',
}) => {
  'data': {for (final e in _entities) e: rows[e] ?? const []},
  'meta': {
    'page': page,
    'per_page': 200,
    'is_last_page': last,
    'until': until,
    'cursor': last ? cursor : null,
  },
  'message': null,
};

void main() {
  late AppDatabase db;
  late SyncService service;
  late FakeHttpAdapter adapter;
  late List<Map<String, dynamic>> pages;
  late Set<int> failingPages;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    pages = [];
    failingPages = {};
    adapter = FakeHttpAdapter((options) {
      if (options.path == '/sync/bootstrap') {
        return FakeHttpAdapter.json(200, _bootstrap());
      }
      final page = int.parse('${options.queryParameters['page'] ?? 1}');
      if (failingPages.remove(page)) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'connection lost',
        );
      }
      return FakeHttpAdapter.json(200, pages[page - 1]);
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    service = SyncService(dio, db);
    await service.bootstrap();
    adapter.requests.clear();
  });
  tearDown(() => db.close());

  Future<CustomerTableData> customer(int serverId) =>
      (db.select(db.customerTable)..where((t) => t.serverId.equals(serverId)))
          .getSingle();

  Future<String> storedCursor() async => (await (db.select(db.syncStateTable)
            ..where((t) => t.key.equals(SyncService.pullCursorKey)))
          .getSingle())
      .value;

  test('applies edits and new records by server id without duplicating', () async {
    pages = [
      _page({
        'customers': [
          {'id': 11, 'client_uuid': 'cust-uuid-11', 'name': 'Ana María', 'phone_number': '999', 'enabled': true},
          {'id': 13, 'client_uuid': null, 'name': 'Carla', 'phone_number': null, 'enabled': true},
        ],
        'customer_addresses': [
          {'id': 111, 'customer_id': 11, 'street': 'Belgrano 500', 'is_primary': true, 'enabled': true},
          {'id': 131, 'customer_id': 13, 'street': 'Mitre 10', 'is_primary': true, 'enabled': true},
        ],
        'products': [
          {'id': 21, 'name': 'Water 20L (new)', 'description': null, 'enabled': true},
        ],
        'route_stops': [
          {
            'id': 71,
            'route_id': 7,
            'customer_id': 11,
            'address_id': 111,
            'scheduled_time': '10:00:00',
            'is_rescheduled_from': null,
            'status': 'FINISHED',
            'enabled': true,
          },
          {
            'id': 73,
            'route_id': 7,
            'customer_id': 13,
            'address_id': 131,
            'scheduled_time': null,
            'is_rescheduled_from': null,
            'status': 'PENDING',
            'enabled': true,
          },
        ],
      }),
    ];

    await service.pull();
    await service.pull();

    expect((await db.select(db.customerTable).get()).length, 3);
    final ana = await customer(11);
    expect(ana.customerId, 'cust-uuid-11');
    expect(ana.name, 'Ana María');
    expect(ana.phone, '999');
    final carla = await customer(13);
    expect(carla.name, 'Carla');

    final addresses = await db.select(db.customerAddressTable).get();
    expect(addresses.length, 2);
    expect(addresses.firstWhere((a) => a.serverId == 111).street, 'Belgrano 500');
    expect(addresses.firstWhere((a) => a.serverId == 131).customerId, carla.customerId);

    final products = await db.select(db.productTable).get();
    expect(products.length, 2);
    expect(products.firstWhere((p) => p.serverId == 21).name, 'Water 20L (new)');

    final stops = await db.select(db.routeStopTable).get();
    expect(stops.length, 3);
    final edited = stops.firstWhere((s) => s.serverId == 71);
    expect(edited.status, 'done');
    expect(edited.scheduledTime, '10:00:00');
    final added = stops.firstWhere((s) => s.serverId == 73);
    expect(added.customerId, carla.customerId);
    expect(added.sequence, 3);
  });

  test('stores the product container_type_id when present and null when absent', () async {
    pages = [
      _page({
        'products': [
          {'id': 21, 'name': 'Water 20L', 'description': null, 'enabled': true, 'container_type_id': 1},
          {'id': 22, 'name': 'Soda 2L', 'description': null, 'enabled': true},
          {'id': 23, 'name': 'Ice', 'description': null, 'enabled': true},
        ],
      }),
    ];

    await service.pull();

    final products = await db.select(db.productTable).get();
    expect(products.firstWhere((p) => p.serverId == 21).containerTypeId, 1);
    expect(products.firstWhere((p) => p.serverId == 22).containerTypeId, isNull);
    expect(products.firstWhere((p) => p.serverId == 23).containerTypeId, isNull);
  });

  test('applies an address shaped like the server, with an integer floor and decimal strings', () async {
    pages = [
      _page({
        'customer_addresses': [
          {
            'id': 111,
            'customer_id': 11,
            'street': 'Belgrano 500',
            'apartment': 'B',
            'floor': 3,
            'latitude': '-34.6037000',
            'longitude': '-58.3816000',
            'visual_reference': null,
            'neighborhood': null,
            'is_primary': true,
            'enabled': true,
          },
        ],
      }),
    ];
    final before = await storedCursor();

    await service.pull();

    final address = await (db.select(db.customerAddressTable)
          ..where((t) => t.serverId.equals(111)))
        .getSingle();
    expect(address.floor, '3');
    expect(address.latitude, closeTo(-34.6037, 1e-6));
    expect(await storedCursor(), isNot(before));
  });

  test('a free-text floor on the device survives a server address without floor', () async {
    await (db.update(db.customerAddressTable)..where((t) => t.serverId.equals(111)))
        .write(const CustomerAddressTableCompanion(floor: Value('PB')));
    pages = [
      _page({
        'customer_addresses': [
          {'id': 111, 'customer_id': 11, 'street': 'Belgrano 500', 'floor': null, 'is_primary': true, 'enabled': true},
        ],
      }),
    ];

    await service.pull();

    final address = await (db.select(db.customerAddressTable)
          ..where((t) => t.serverId.equals(111)))
        .getSingle();
    expect(address.floor, 'PB');
  });

  test('a disabled record disappears from lists and selectors without being deleted', () async {
    pages = [
      _page({
        'customers': [
          {'id': 12, 'client_uuid': 'cust-uuid-12', 'name': 'Beto', 'phone_number': null, 'enabled': false},
        ],
        'products': [
          {'id': 22, 'name': 'Soda 2L', 'description': null, 'enabled': false},
        ],
        'visit_outcomes': [
          {'id': 3, 'name': 'Absent', 'triggers_reschedule': true, 'enabled': false},
          {'id': 4, 'name': 'Delivered', 'triggers_reschedule': false, 'enabled': true},
        ],
        'payment_methods': [
          {'id': 5, 'code': 'CASH', 'name': 'Cash', 'enabled': false},
        ],
        'container_types': [
          {'id': 1, 'code': 'BIDON_20L', 'description': '20L', 'enabled': false},
        ],
        'customer_addresses': [
          {'id': 111, 'customer_id': 11, 'street': 'Belgrano 340', 'is_primary': true, 'enabled': false},
        ],
      }),
    ];

    await service.pull();

    final customers = DriftCustomerRepository(db);
    expect((await customers.watchAllCustomers().first).map((c) => c.name), ['Ana']);
    expect((await customers.getCustomersPage(page: 0, pageSize: 10)).map((c) => c.name), ['Ana']);
    expect((await customers.searchCustomers(query: 'Beto', page: 0, pageSize: 10)).map((c) => c.name), isEmpty);
    expect(await customers.watchCustomerCount().first, 1);
    expect((await customers.watchAllCustomers().first).single.addresses, isEmpty);

    final products = await DriftProductRepository(db).watchAllProducts().first;
    expect(products.map((p) => p.name), ['Water 20L']);

    final outcomes = await DriftVisitRepository(db).watchOutcomes().first;
    expect(outcomes.map((o) => o.id), [4]);

    final stops = await DriftRouteRepository(db).watchDayStops().first;
    expect(stops.map((s) => s.customer.name), ['Ana']);

    expect((await db.select(db.customerTable).get()).length, 2);
    expect((await db.select(db.productTable).get()).length, 2);
    expect((await db.select(db.visitOutcomeTable).get()).length, 2);
    expect((await db.select(db.paymentMethodTable).get()).length, 1);
    expect((await db.select(db.containerTypeTable).get()).length, 1);
    expect((await db.select(db.customerAddressTable).get()).length, 1);
  });

  test('server balances replace the local ones', () async {
    final ana = await customer(11);
    await (db.update(db.customerBalanceTable)
          ..where((t) => t.customerId.equals(ana.customerId)))
        .write(const CustomerBalanceTableCompanion(currentBalance: Value(9999)));
    pages = [
      _page({
        'customer_balances': [
          {'id': 500, 'customer_id': 11, 'current_balance': '250.75', 'enabled': true},
        ],
        'customer_container_balances': [
          {'id': 1300, 'customer_id': 11, 'container_type_id': 1, 'balance': 7, 'enabled': true},
        ],
      }),
    ];

    await service.pull();

    final balance = await db.select(db.customerBalanceTable).getSingle();
    expect(balance.currentBalance, 250.75);
    final containers = await db.select(db.customerContainerBalanceTable).getSingle();
    expect(containers.quantity, 7);
    final stops = await DriftRouteRepository(db).watchDayStops().first;
    expect(stops.firstWhere((s) => s.customer.name == 'Ana').customer.debtAmount, 250.75);
  });

  group('custody', () {
    Future<int> held(String code) async => (await (db.select(db.customerContainerBalanceTable)
              ..where((t) => t.customerId.equals('cust-uuid-11') & t.containerType.equals(code)))
            .getSingle())
        .quantity;

    Map<String, dynamic> serverCustody(int balance) => _page({
      'customer_container_balances': [
        {'id': 1300, 'customer_id': 11, 'container_type_id': 1, 'balance': balance, 'enabled': true},
      ],
    });

    test('is the server value plus the unsent container movements', () async {
      await DriftInventoryRepository(db).recordContainerMovement(
        ContainerMovement(
          id: 'mov-1',
          customerId: 'cust-uuid-11',
          containerType: 'BIDON_20L',
          deliveredQuantity: 2,
          returnedQuantity: 0,
          createdAt: DateTime(2026, 10, 19, 10),
        ),
      );
      pages = [serverCustody(7)];

      await service.pull();

      expect(await held('BIDON_20L'), 7 + 2);
    });

    test('takes the server value while only sales or payments are unsent', () async {
      await db.into(db.paymentTable).insert(
            PaymentTableCompanion.insert(
              paymentId: const Value('pay-1'),
              customerId: 'cust-uuid-11',
              amount: 100,
              paymentMethod: 'EFECTIVO',
            ),
          );
      await DriftPendingChangeRepository(db).enqueue(
        entity: PendingEntity.payment,
        entityId: 'pay-1',
        action: PendingAction.insert,
      );
      pages = [serverCustody(7)];

      await service.pull();

      expect(await held('BIDON_20L'), 7);
    });
  });

  test('keeps rows with unsent local changes and adds unsent payments to the server balance', () async {
    final ana = await customer(11);
    await (db.update(db.customerTable)..where((t) => t.customerId.equals(ana.customerId)))
        .write(const CustomerTableCompanion(name: Value('Ana (edited)')));
    final queue = DriftPendingChangeRepository(db);
    await queue.enqueue(
      entity: PendingEntity.customer,
      entityId: ana.customerId,
      action: PendingAction.update,
    );
    await db.into(db.paymentTable).insert(
          PaymentTableCompanion.insert(
            paymentId: const Value('pay-1'),
            customerId: ana.customerId,
            amount: 100,
            paymentMethod: 'CASH',
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.payment,
      entityId: 'pay-1',
      action: PendingAction.insert,
    );
    pages = [
      _page({
        'customers': [
          {'id': 11, 'client_uuid': 'cust-uuid-11', 'name': 'Ana (server)', 'phone_number': '111', 'enabled': true},
        ],
        'customer_balances': [
          {'id': 500, 'customer_id': 11, 'current_balance': '0.00', 'enabled': true},
        ],
      }),
    ];

    await service.pull();

    expect((await customer(11)).name, 'Ana (edited)');
    // Server balance 0.00 minus the pending payment of 100.
    expect((await db.select(db.customerBalanceTable).getSingle()).currentBalance, -100);
    expect(await storedCursor(), '2026-10-19T12:59:55+00:00');
  });

  test('a new server address is added next to addresses already linked to the server', () async {
    pages = [
      _page({
        'customer_addresses': [
          {'id': 112, 'customer_id': 11, 'street': 'Mitre 900', 'is_primary': true, 'enabled': true},
        ],
      }),
    ];

    await service.pull();

    final ana = await customer(11);
    final addresses = await (db.select(db.customerAddressTable)
          ..where((t) => t.customerId.equals(ana.customerId)))
        .get();
    expect(addresses.map((a) => a.serverId).toSet(), {111, 112});
    expect(addresses.firstWhere((a) => a.serverId == 111).street, 'Belgrano 340');
  });

  test('a cut halfway through the pages keeps the previous cursor and the retry applies everything', () async {
    pages = [
      _page(
        {
          'customers': [
            {'id': 11, 'client_uuid': 'cust-uuid-11', 'name': 'Ana María', 'phone_number': '111', 'enabled': true},
          ],
        },
        page: 1,
        last: false,
      ),
      _page(
        {
          'customers': [
            {'id': 13, 'client_uuid': null, 'name': 'Carla', 'phone_number': null, 'enabled': true},
          ],
        },
        page: 2,
        cursor: '2026-10-19T12:59:55+00:00',
      ),
    ];
    failingPages = {2};

    await expectLater(service.pull(), throwsA(isA<DioException>()));

    expect(await storedCursor(), '2026-10-19T12:00:00+00:00');
    expect((await customer(11)).name, 'Ana');
    expect((await db.select(db.customerTable).get()).length, 2);

    adapter.requests.clear();
    await service.pull();

    expect(await storedCursor(), '2026-10-19T12:59:55+00:00');
    expect((await customer(11)).name, 'Ana María');
    expect((await customer(13)).name, 'Carla');
    expect(adapter.requests.map((r) => r.queryParameters), [
      {'cursor': '2026-10-19T12:00:00+00:00', 'page': 1},
      {'cursor': '2026-10-19T12:00:00+00:00', 'until': '2026-10-19T13:00:00+00:00', 'page': 2},
    ]);
  });
}
