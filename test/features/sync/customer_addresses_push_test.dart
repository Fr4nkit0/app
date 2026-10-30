import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer_address.repository.dart';
import 'package:app/features/customers/domain/models/address_details.dart';
import 'package:app/features/customers/domain/models/customer_edit.dart';
import 'package:app/features/customers/domain/usecases/add_address.usecase.dart';
import 'package:app/features/customers/domain/usecases/disable_address.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit.customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit_address.usecase.dart';
import 'package:app/features/customers/domain/usecases/set_primary_address.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

void main() {
  late AppDatabase db;
  late SyncEngine engine;
  late PendingChangeRepository queue;
  late List<Json> pushBodies;
  late Json? Function(String entity, Json record)? answer;

  final longAgo = DateTime(2020, 1, 1);
  final now = DateTime(2026, 10, 29, 12);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    pushBodies = [];
    answer = null;
    var nextId = 900;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter((options) async {
        final body = Map<String, dynamic>.from(options.data as Map);
        pushBodies.add(body);
        return FakeHttpAdapter.json(200, {
          'data': {
            for (final MapEntry(key: entity, value: records) in body.entries)
              entity: [
                for (final r in records as List)
                  answer?.call(entity, Map<String, dynamic>.from(r as Map)) ??
                      {
                        'uuid': (r as Map)['uuid'],
                        'status': 'accepted',
                        'server_id': ++nextId,
                        'review_reason': null,
                      },
              ],
          },
          'message': null,
        });
      });
    engine = SyncEngine(dio: dio, db: db, sync: SyncService(dio, db));
    queue = DriftPendingChangeRepository(db);

    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
            serverId: const drift.Value(10),
            lastModifiedDate: drift.Value(longAgo),
          ),
        );
    for (final (id, primary, serverId) in [
      ('a-1', true, 101),
      ('a-2', false, 102),
    ]) {
      await db
          .into(db.customerAddressTable)
          .insert(
            CustomerAddressTableCompanion.insert(
              addressId: drift.Value(id),
              customerId: const drift.Value('c-1'),
              street: drift.Value('Street $id'),
              neighborhood: const drift.Value('Centro'),
              isPrimary: drift.Value(primary),
              latitude: const drift.Value(-24.78),
              longitude: const drift.Value(-65.41),
              serverId: drift.Value(serverId),
              createdAt: drift.Value(longAgo),
              lastModifiedDate: drift.Value(longAgo),
            ),
          );
    }
  });
  tearDown(() => db.close());

  DriftCustomerAddressRepository repo() =>
      DriftCustomerAddressRepository(db, now: () => now);
  final runner = driftTransactionRunner;

  List<Json> recordsIn(Json body, String key) => [
    for (final r in body[key] as List) Map<String, dynamic>.from(r as Map),
  ];

  Future<CustomerAddressTableData> row(String id) => (db.select(
    db.customerAddressTable,
  )..where((t) => t.addressId.equals(id))).getSingle();

  test('an edited address travels under customer_addresses with exactly the '
      'contract fields, strict booleans and a UTC modified_at', () async {
    await EditAddressUseCase(
      addressRepo: repo(),
      transaction: runner(db),
    ).execute(
      addressId: 'a-2',
      details: const AddressDetails(
        street: 'Mitre 50',
        neighborhood: 'Centro',
        apartment: 'B',
        floor: ' PB ',
        visualReference: 'Portón negro',
      ),
    );

    await engine.push();

    final body = pushBodies.single;
    expect(body.keys, ['customer_addresses']);
    final record = recordsIn(body, 'customer_addresses').single;
    expect(record, {
      'uuid': 'a-2',
      'server_id': 102,
      'customer_id': 10,
      'street': 'Mitre 50',
      'apartment': 'B',
      'floor': 'PB',
      'visual_reference': 'Portón negro',
      'neighborhood': 'Centro',
      'latitude': -24.78,
      'longitude': -65.41,
      'is_primary': false,
      'enabled': true,
      'modified_at': now.toUtc().toIso8601String(),
    });
    expect(record['is_primary'], isA<bool>());
    expect(record['enabled'], isA<bool>());
    expect(record['modified_at'], endsWith('Z'));
    expect(await queue.countPending(), 0);
  });

  test('an added address has no server_id until the server accepts it, then '
      'stores it', () async {
    final id =
        await AddAddressUseCase(
          addressRepo: repo(),
          transaction: runner(db),
        ).execute(
          customerId: 'c-1',
          details: const AddressDetails(street: 'Mitre 50'),
        );

    await engine.push();

    final record = recordsIn(pushBodies.single, 'customer_addresses').single;
    expect(record['uuid'], id);
    expect(record.containsKey('server_id'), isFalse);
    expect(record['is_primary'], false);
    expect(record['enabled'], true);
    expect(record['floor'], isNull);
    expect((await row(id)).serverId, 901);
    expect(await queue.countPending(), 0);
  });

  test('a disabled address travels with enabled false', () async {
    await DisableAddressUseCase(
      addressRepo: repo(),
      transaction: runner(db),
    ).execute('a-2');

    await engine.push();

    final record = recordsIn(pushBodies.single, 'customer_addresses').single;
    expect(record['uuid'], 'a-2');
    expect(record['enabled'], false);
    expect(record['is_primary'], false);
  });

  test('a new primary travels before the previous one, which is newer so '
      'its own fields still apply', () async {
    await SetPrimaryAddressUseCase(
      addressRepo: repo(),
      transaction: runner(db),
    ).execute('a-2');

    await engine.push();

    final records = recordsIn(pushBodies.single, 'customer_addresses');
    expect([for (final r in records) r['uuid']], ['a-2', 'a-1']);
    expect([for (final r in records) r['is_primary']], [true, false]);
    expect(
      DateTime.parse(
        records.last['modified_at'] as String,
      ).isAfter(DateTime.parse(records.first['modified_at'] as String)),
      isTrue,
    );
  });

  test('the primary travels first even when the old primary was queued '
      'earlier', () async {
    await EditAddressUseCase(
      addressRepo: repo(),
      transaction: runner(db),
    ).execute(
      addressId: 'a-1',
      details: const AddressDetails(street: 'Belgrano 1'),
    );
    await SetPrimaryAddressUseCase(
      addressRepo: repo(),
      transaction: runner(db),
    ).execute('a-2');

    await engine.push();

    final records = recordsIn(pushBodies.single, 'customer_addresses');
    expect([for (final r in records) r['uuid']], ['a-2', 'a-1']);
    expect(records.last['street'], 'Belgrano 1');
  });

  test('a rejected address keeps the server reason', () async {
    await EditAddressUseCase(
      addressRepo: repo(),
      transaction: runner(db),
    ).execute(
      addressId: 'a-2',
      details: const AddressDetails(street: 'Mitre 50'),
    );
    answer = (entity, r) => {
      'uuid': r['uuid'],
      'status': 'rejected',
      'error': 'The record belongs to another customer.',
    };

    await engine.push();

    final rejected = await queue.getRejected();
    expect(rejected.single.entity, PendingEntity.customerAddress);
    expect(rejected.single.entityId, 'a-2');
    expect(
      rejected.single.rejectionReason,
      'The record belongs to another customer.',
    );
    expect((await row('a-2')).serverId, 102);
  });

  test('an address of a customer the server does not know yet references it '
      'by uuid, in the same push after the customer', () async {
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-new'),
            name: 'Nuevo',
          ),
        );
    await db
        .into(db.customerAddressTable)
        .insert(
          CustomerAddressTableCompanion.insert(
            addressId: const drift.Value('n-1'),
            customerId: const drift.Value('c-new'),
            street: const drift.Value('Alvarado 1'),
            isPrimary: const drift.Value(true),
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.customer,
      entityId: 'c-new',
      action: PendingAction.insert,
    );
    final id =
        await AddAddressUseCase(
          addressRepo: repo(),
          transaction: runner(db),
        ).execute(
          customerId: 'c-new',
          details: const AddressDetails(street: 'Alvarado 2'),
        );

    await engine.push();

    final body = pushBodies.single;
    expect(body.keys.toList(), ['customers', 'customer_addresses']);
    final record = recordsIn(body, 'customer_addresses').single;
    expect(record['uuid'], id);
    expect(record['customer_uuid'], 'c-new');
    expect(record.containsKey('customer_id'), isFalse);
  });

  test('a known customer edit waits while its address changes are unsent, so '
      'it edits the new primary on the server', () async {
    await SetPrimaryAddressUseCase(
      addressRepo: repo(),
      transaction: runner(db),
    ).execute('a-2');
    await EditCustomerUseCase(
      customerRepository: DriftCustomerRepository(db),
      transaction: runner(db),
    ).execute(
      const CustomerEdit(
        customerId: 'c-1',
        name: 'Kiosco Sur',
        street: 'Street a-2',
        neighborhood: 'Centro',
      ),
    );

    await engine.push();

    expect(pushBodies.first.keys.toList(), ['customer_addresses']);
    expect(await queue.countPending(), 1);

    await engine.push();

    final customer = recordsIn(pushBodies.last, 'customers').single;
    expect(customer['name'], 'Kiosco Sur');
    expect((customer['address'] as Map)['uuid'], 'a-2');
    expect(await queue.countPending(), 0);
  });

  test('the push order follows the server', () {
    final keys = [for (final p in SyncEngine.defaultPushers(db)) p.wireKey];
    const serverOrder = [
      'customers',
      'customer_addresses',
      'customer_preferences',
      'customer_agreements',
      'route_stops',
      'visits',
      'container_movements',
      'sales',
      'payments',
      'sale_cancellations',
      'payment_cancellations',
    ];
    expect(keys, [
      for (final k in serverOrder)
        if (keys.contains(k)) k,
    ]);
    expect(keys, contains('customer_addresses'));
    expect(keys.indexOf('customer_addresses'), keys.indexOf('customers') + 1);
  });
}
