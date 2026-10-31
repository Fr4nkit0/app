import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer_address.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer_preference.repository.dart';
import 'package:app/features/customers/domain/models/address_details.dart';
import 'package:app/features/customers/domain/models/customer_edit.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/customers/domain/usecases/add_address.usecase.dart';
import 'package:app/features/customers/domain/usecases/add_preference.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit.customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit_preference.usecase.dart';
import 'package:app/features/history/data/repositories/history.repository.dart';
import 'package:app/features/history/domain/models/customer_record.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

const _foreign = 'Customer is assigned to another driver.';

/// Edits of a customer assigned to another driver wait for the admin's
/// approval (S3); customers that left the driver are hidden, keeping their
/// history (S4, APP-32).
void main() {
  late AppDatabase db;
  late SyncEngine engine;
  late SyncService sync;
  late PendingChangeRepository queue;
  late List<Json> pushBodies;
  late Map<String, List<Json>> pullRows;
  late Json? Function(String entity, Json record)? answer;

  final longAgo = DateTime(2020, 1, 1);
  final now = DateTime(2026, 10, 31, 12);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    pushBodies = [];
    pullRows = {};
    answer = null;
    var nextId = 900;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter((options) async {
        if (options.path == '/sync/pull') {
          return FakeHttpAdapter.json(200, {
            'data': pullRows,
            'meta': {
              'page': 1,
              'per_page': 200,
              'is_last_page': true,
              'until': '2026-10-31T13:00:00+00:00',
              'cursor': '2026-10-31T12:59:55+00:00',
            },
            'message': null,
          });
        }
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
                        'review_reasons': <String>[],
                      },
              ],
          },
          'message': null,
        });
      });
    sync = SyncService(dio, db);
    engine = SyncEngine(dio: dio, db: db, sync: sync);
    queue = DriftPendingChangeRepository(db);

    // A customer the server knows, with its primary address and a Monday
    // preference, and a second one created on the device.
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
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-2'),
            name: 'Almacen Sur',
            serverId: const drift.Value(20),
            lastModifiedDate: drift.Value(longAgo),
          ),
        );
    await db
        .into(db.customerAddressTable)
        .insert(
          CustomerAddressTableCompanion.insert(
            addressId: const drift.Value('a-1'),
            customerId: const drift.Value('c-1'),
            street: const drift.Value('Belgrano 100'),
            neighborhood: const drift.Value('Centro'),
            visualReference: const drift.Value('Porton verde'),
            isPrimary: const drift.Value(true),
            serverId: const drift.Value(101),
            createdAt: drift.Value(longAgo),
            lastModifiedDate: drift.Value(longAgo),
          ),
        );
    await db
        .into(db.customerPreferenceTable)
        .insert(
          CustomerPreferenceTableCompanion.insert(
            customerPreferenceId: const drift.Value('p-1'),
            customerId: const drift.Value('c-1'),
            dayOfWeek: const drift.Value(1),
            timeWindowStart: '09:00',
            timeWindowEnd: const drift.Value('12:00'),
            serverId: const drift.Value(201),
            createdAt: drift.Value(longAgo),
            lastModifiedDate: drift.Value(longAgo),
          ),
        );
  });
  tearDown(() => db.close());

  final runner = driftTransactionRunner;

  /// The server's answer for an edit of another driver's customer: nothing
  /// applied, the row id when the edit points at one.
  Json foreignAll(String entity, Json r) => {
    'uuid': r['uuid'],
    'status': 'accepted',
    'server_id': r['server_id'],
    'review_reasons': [_foreign],
  };

  Future<CustomerTableData> customer(String id) => (db.select(
    db.customerTable,
  )..where((t) => t.customerId.equals(id))).getSingle();

  Future<CustomerPreferenceTableData> preference(String id) => (db.select(
    db.customerPreferenceTable,
  )..where((t) => t.customerPreferenceId.equals(id))).getSingle();

  Future<PendingChange?> latest(PendingEntity entity, String id) =>
      queue.watchLatestFor(entity, id).first;

  Future<void> editPhone(String phone) =>
      EditCustomerUseCase(
        customerRepository: DriftCustomerRepository(db),
        transaction: runner(db),
      ).execute(
        CustomerEdit(
          customerId: 'c-1',
          name: 'Kiosco Norte',
          phone: phone,
          street: 'Belgrano 100',
          neighborhood: 'Centro',
          visualReference: 'Porton verde',
        ),
      );

  group('S3: an edit of a customer assigned to another driver', () {
    test('keeps the local values, waits for approval, is not counted and is '
        'never sent again', () async {
      await editPhone('111');
      answer = foreignAll;

      await engine.push();
      await engine.push();

      expect((await customer('c-1')).phone, '111');
      expect((await customer('c-1')).serverId, 10);
      expect(
        (await latest(PendingEntity.customer, 'c-1'))?.status,
        PendingStatus.awaitingApproval,
      );
      final status = await engine.status();
      expect(status.pendingCount, 0);
      expect(status.rejectedCount, 0);
      expect(pushBodies, hasLength(1));
    });

    test('of a preference is not rolled back to the server values', () async {
      await EditPreferenceUseCase(
        preferenceRepo: DriftCustomerPreferenceRepository(db, now: () => now),
        transaction: runner(db),
      ).execute(
        preferenceId: 'p-1',
        details: const PreferenceDetails(
          dayOfWeek: 5,
          start: '10:00',
          end: '13:30',
        ),
      );
      answer = foreignAll;

      await engine.push();

      final row = await preference('p-1');
      expect(row.dayOfWeek, 5);
      expect(row.timeWindowStart, '10:00');
      expect(row.serverId, 201);
      expect(
        (await latest(PendingEntity.customerPreference, 'p-1'))?.status,
        PendingStatus.awaitingApproval,
      );
    });

    test('that adds an address is answered without server id: it is kept '
        'unlinked, waits for approval and is sent once', () async {
      final id =
          await AddAddressUseCase(
            addressRepo: DriftCustomerAddressRepository(db),
            transaction: runner(db),
          ).execute(
            customerId: 'c-1',
            details: const AddressDetails(
              street: 'Mitre 50',
              neighborhood: 'Centro',
            ),
          );
      answer = foreignAll;

      await engine.push();
      await engine.push();

      final row = await (db.select(
        db.customerAddressTable,
      )..where((t) => t.addressId.equals(id))).getSingle();
      expect(row.street, 'Mitre 50');
      expect(row.serverId, isNull);
      expect(
        (await latest(PendingEntity.customerAddress, id))?.status,
        PendingStatus.awaitingApproval,
      );
      expect(pushBodies, hasLength(1));
      expect(await queue.countPending(), 0);
    });

    test(
      'a later edit of the same record queues and is sent normally',
      () async {
        await editPhone('111');
        answer = foreignAll;
        await engine.push();

        await editPhone('222');
        expect(await queue.countPending(), 1);
        await engine.push();

        expect(pushBodies, hasLength(2));
        final second = (pushBodies.last['customers'] as List).single as Map;
        expect(second['phone_number'], '222');
        expect((await customer('c-1')).phone, '222');
        expect(
          (await latest(PendingEntity.customer, 'c-1'))?.status,
          PendingStatus.awaitingApproval,
        );
      },
    );

    test('is listed in Historial as waiting for approval', () async {
      await editPhone('111');
      answer = foreignAll;

      await engine.push();

      final entries = await DriftHistoryRepository(db).watchHistory().first;
      expect(entries.single.status, PendingStatus.awaitingApproval);
      expect(entries.single.customerName, 'Kiosco Norte');
      expect(entries.single.isIssue, isFalse);
    });
  });

  group('review_reasons', () {
    test(
      'an accepted answer with other review reasons, or none, is sent',
      () async {
        await editPhone('111');
        answer = (entity, r) => {
          'uuid': r['uuid'],
          'status': 'accepted',
          'server_id': 10,
          'review_reasons': ['Sale amount differs from the price list.'],
        };
        await engine.push();
        expect(
          (await latest(PendingEntity.customer, 'c-1'))?.status,
          PendingStatus.sent,
        );

        await editPhone('222');
        // An older server without the array.
        answer = (entity, r) => {
          'uuid': r['uuid'],
          'status': 'accepted',
          'server_id': 10,
        };
        await engine.push();
        expect(
          (await latest(PendingEntity.customer, 'c-1'))?.status,
          PendingStatus.sent,
        );
      },
    );

    test('an accepted record without server id settles once without being '
        'linked', () async {
      final id =
          await AddPreferenceUseCase(
            preferenceRepo: DriftCustomerPreferenceRepository(
              db,
              now: () => now,
            ),
            transaction: runner(db),
          ).execute(
            customerId: 'c-1',
            details: const PreferenceDetails(
              dayOfWeek: 3,
              start: '08:00',
              end: '10:00',
            ),
          );
      answer = (entity, r) => {
        'uuid': r['uuid'],
        'status': 'accepted',
        'server_id': null,
        'review_reasons': <String>[],
      };

      await engine.push();
      await engine.push();

      expect((await preference(id)).serverId, isNull);
      expect(
        (await latest(PendingEntity.customerPreference, id))?.status,
        PendingStatus.sent,
      );
      expect(pushBodies, hasLength(1));
    });
  });

  group('S4: customers_removed', () {
    Json removed({int? id, String? uuid}) => {
      'customer_id': id ?? 999,
      'client_uuid': uuid,
      'removed_at': '2026-10-31T12:30:00.000000Z',
    };

    Future<List<String>> visibleNames() async {
      final repo = DriftCustomerRepository(db);
      final watched = (await repo.watchAllCustomers().first)
          .map((c) => c.name)
          .toList();
      final paged = (await repo.getCustomersPage(
        page: 0,
        pageSize: 10,
      )).map((c) => c.name).toList();
      final searched = (await repo.searchCustomers(
        query: '',
        page: 0,
        pageSize: 10,
      )).map((c) => c.name).toList();
      expect(paged..sort(), watched.toList()..sort());
      expect(searched..sort(), watched.toList()..sort());
      expect(await repo.watchCustomerCount().first, watched.length);
      return watched..sort();
    }

    test('hides a customer matched by server id from Clientes and sales, '
        'keeping it and its history', () async {
      await editPhone('111');
      await engine.push();
      await db
          .into(db.paymentTable)
          .insert(
            PaymentTableCompanion.insert(
              paymentId: const drift.Value('pay-1'),
              customerId: 'c-1',
              amount: 1500,
              paymentMethod: 'EFECTIVO',
            ),
          );
      pullRows = {
        'customers_removed': [removed(id: 10)],
      };

      await sync.pull();

      expect(await visibleNames(), ['Almacen Sur']);
      expect(
        await DriftCustomerRepository(
          db,
        ).searchCustomers(query: 'Kiosco', page: 0, pageSize: 10),
        isEmpty,
      );
      expect((await customer('c-1')).name, 'Kiosco Norte');
      final history = DriftHistoryRepository(db);
      final entries = await history.watchHistory().first;
      expect(entries.single.customerName, 'Kiosco Norte');
      final records = await history.watchCustomerRecords('c-1').first;
      expect(records.single.type, CustomerRecordType.payment);
      expect(records.single.id, 'pay-1');
    });

    test(
      'the Clientes list watching the customers drops it after the pull',
      () async {
        final names = DriftCustomerRepository(db).watchAllCustomers().map(
          (list) => [for (final c in list) c.name]..sort(),
        );
        final emitted = expectLater(names, emitsThrough(['Almacen Sur']));
        pullRows = {
          'customers_removed': [removed(id: 10)],
        };

        await sync.pull();

        await emitted;
      },
    );

    test('hides a customer matched by its client uuid', () async {
      pullRows = {
        'customers_removed': [removed(uuid: 'c-2')],
      };

      await sync.pull();

      expect(await visibleNames(), ['Kiosco Norte']);
    });

    test('ignores customers the device does not know', () async {
      pullRows = {
        'customers_removed': [removed(id: 555, uuid: 'nope')],
      };

      await sync.pull();

      expect(await visibleNames(), ['Almacen Sur', 'Kiosco Norte']);
    });

    test('a customer reassigned back shows again', () async {
      pullRows = {
        'customers_removed': [removed(id: 10)],
      };
      await sync.pull();
      expect(await visibleNames(), ['Almacen Sur']);

      pullRows = {
        'customers': [
          {
            'id': 10,
            'client_uuid': null,
            'name': 'Kiosco Norte',
            'phone_number': '3874001122',
            'enabled': true,
          },
        ],
      };
      await sync.pull();

      expect(await visibleNames(), ['Almacen Sur', 'Kiosco Norte']);
    });

    test(
      'a hidden customer is not disabled, so no push turns it off',
      () async {
        pullRows = {
          'customers_removed': [removed(id: 10)],
        };

        await sync.pull();

        expect((await customer('c-1')).enabled, isTrue);
        expect(await queue.countPending(), 0);
      },
    );
  });
}
