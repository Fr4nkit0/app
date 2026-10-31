import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer_address.repository.dart';
import 'package:app/features/customers/domain/models/address_details.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer_edit.dart';
import 'package:app/features/customers/domain/usecases/disable_customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit.customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit_address.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

/// An edit of a record the server knows carries only the fields the driver
/// changed (S1, S2): the server merges them field by field.
void main() {
  late AppDatabase db;
  late SyncEngine engine;
  late PendingChangeRepository queue;
  late List<Json> pushBodies;
  late Json? Function(String entity, Json record)? answer;

  final longAgo = DateTime(2020, 1, 1);

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
                        'server_id': r['server_id'] ?? ++nextId,
                        'review_reason': null,
                      },
              ],
          },
          'message': null,
        });
      });
    engine = SyncEngine(dio: dio, db: db, sync: SyncService(dio, db));
    queue = DriftPendingChangeRepository(db);

    // A customer the server knows, with its primary and a second address.
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
            phone: const drift.Value('3874001122'),
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
              visualReference: const drift.Value('Porton verde'),
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

  final runner = driftTransactionRunner;
  DriftCustomerRepository customers() => DriftCustomerRepository(db);
  DriftCustomerAddressRepository addresses() =>
      DriftCustomerAddressRepository(db);

  /// The customer form as the driver submits it: every field, starting
  /// from what is stored.
  Future<void> editCustomer({
    String name = 'Kiosco Norte',
    String? phone = '3874001122',
    String? street = 'Street a-1',
    String? visualReference = 'Porton verde',
  }) =>
      EditCustomerUseCase(
        customerRepository: customers(),
        transaction: runner(db),
      ).execute(
        CustomerEdit(
          customerId: 'c-1',
          name: name,
          phone: phone,
          street: street,
          neighborhood: 'Centro',
          visualReference: visualReference,
        ),
      );

  List<Json> recordsIn(Json body, String key) => [
    for (final r in body[key] as List) Map<String, dynamic>.from(r as Map),
  ];

  Json customerRecord() => recordsIn(pushBodies.last, 'customers').single;

  test(
    'a phone edited offline travels alone: no name and no address, so '
    'the address the office changed is left alone (audit E3 round C)',
    () async {
      await editCustomer(phone: '3874009988');

      await engine.push();

      final record = customerRecord();
      expect(record.keys.toSet(), {
        'uuid',
        'server_id',
        'modified_at',
        'phone_number',
      });
      expect(record['uuid'], 'c-1');
      expect(record['server_id'], 10);
      expect(record['phone_number'], '3874009988');
      expect(record['modified_at'], endsWith('Z'));
      expect(await queue.countPending(), 0);
    },
  );

  test('an address field edited through the customer form travels as the '
      'address uuid plus that field', () async {
    await editCustomer(visualReference: 'Porton AZUL');

    await engine.push();

    final record = customerRecord();
    expect(record.keys.toSet(), {
      'uuid',
      'server_id',
      'modified_at',
      'address',
    });
    expect(record['address'], {
      'uuid': 'a-1',
      'visual_reference': 'Porton AZUL',
    });
  });

  test('an address visual reference edit pushes only that field', () async {
    await EditAddressUseCase(
      addressRepo: addresses(),
      transaction: runner(db),
    ).execute(
      addressId: 'a-2',
      details: const AddressDetails(
        street: 'Street a-2',
        neighborhood: 'Centro',
        visualReference: 'Porton AZUL',
      ),
    );

    await engine.push();

    final record = recordsIn(pushBodies.single, 'customer_addresses').single;
    expect(record.keys.toSet(), {
      'uuid',
      'server_id',
      'customer_id',
      'modified_at',
      'visual_reference',
    });
    expect(record['uuid'], 'a-2');
    expect(record['server_id'], 102);
    expect(record['customer_id'], 10);
    expect(record['visual_reference'], 'Porton AZUL');
  });

  test('two queued edits of one customer push one record with both fields '
      'and their latest values', () async {
    await editCustomer(phone: '111');
    await editCustomer(phone: '111', name: 'Kiosco Sur');

    await engine.push();

    final record = customerRecord();
    expect(record.keys.toSet(), {
      'uuid',
      'server_id',
      'modified_at',
      'phone_number',
      'name',
    });
    expect(record['phone_number'], '111');
    expect(record['name'], 'Kiosco Sur');
    expect(await queue.countPending(), 0);
  });

  test('a customer the server does not know yet still travels whole, even '
      'when it was edited before the push', () async {
    await customers().saveCustomer(
      Customer(
        id: 'c-new',
        name: 'Nuevo',
        phone: '3870000000',
        addresses: [
          CustomerAddress(
            id: 'n-1',
            street: 'Alvarado 1',
            floor: '3',
            isPrimary: true,
            latitude: -24.7,
            longitude: -65.4,
          ),
        ],
        preferences: const [],
      ),
    );
    await EditCustomerUseCase(
      customerRepository: customers(),
      transaction: runner(db),
    ).execute(
      const CustomerEdit(
        customerId: 'c-new',
        name: 'Nuevo',
        phone: '3871111111',
        street: 'Alvarado 1',
        floor: '3',
      ),
    );

    await engine.push();

    final record = recordsIn(pushBodies.single, 'customers').single;
    expect(record.containsKey('server_id'), isFalse);
    expect(record['name'], 'Nuevo');
    expect(record['phone_number'], '3871111111');
    expect(record['address'], {
      'uuid': 'n-1',
      'street': 'Alvarado 1',
      'apartment': null,
      'floor': '3',
      'visual_reference': null,
      'neighborhood': null,
      'latitude': -24.7,
      'longitude': -65.4,
    });
  });

  test('a cleared phone travels as null', () async {
    await editCustomer(phone: null);

    await engine.push();

    final record = customerRecord();
    expect(record.containsKey('phone_number'), isTrue);
    expect(record['phone_number'], isNull);
    expect(record.containsKey('name'), isFalse);
  });

  test('a disable travels as enabled false only', () async {
    await DisableCustomerUseCase(
      customerRepository: customers(),
      transaction: runner(db),
    ).execute('c-1');

    await engine.push();

    expect(customerRecord(), {
      'uuid': 'c-1',
      'server_id': 10,
      'modified_at': isA<String>(),
      'enabled': false,
    });
  });

  test('an outdated answer settles the queue and is not sent again', () async {
    await editCustomer(phone: '3874009988');
    await EditAddressUseCase(
      addressRepo: addresses(),
      transaction: runner(db),
    ).execute(
      addressId: 'a-2',
      details: const AddressDetails(
        street: 'Street a-2 bis',
        neighborhood: 'Centro',
        visualReference: 'Porton verde',
      ),
    );
    answer = (entity, r) => {
      'uuid': r['uuid'],
      'status': 'outdated',
      'server_id': r['server_id'],
      'review_reason': null,
    };

    await engine.push();
    await engine.push();
    await engine.push();

    expect(await queue.countPending(), 0);
    expect(await queue.getRejected(), isEmpty);
    expect(pushBodies.expand((b) => b.keys), [
      'customer_addresses',
      'customers',
    ]);
  });

  test('an edit that changes nothing queues nothing', () async {
    await editCustomer();
    await EditAddressUseCase(
      addressRepo: addresses(),
      transaction: runner(db),
    ).execute(
      addressId: 'a-2',
      details: const AddressDetails(
        street: 'Street a-2',
        neighborhood: 'Centro',
        visualReference: 'Porton verde',
      ),
    );

    expect(await queue.countPending(), 0);
  });

  test('an edit queued by an older version, without its changed fields, '
      'still travels whole', () async {
    await queue.enqueue(
      entity: PendingEntity.customer,
      entityId: 'c-1',
      action: PendingAction.update,
      payload: {'customerId': 'c-1', 'name': 'Kiosco Norte'},
    );

    await engine.push();

    final record = customerRecord();
    expect(record['name'], 'Kiosco Norte');
    expect(record['phone_number'], '3874001122');
    expect((record['address'] as Map)['street'], 'Street a-1');
  });
}
