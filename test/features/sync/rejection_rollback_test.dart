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
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer_edit.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/customers/domain/usecases/add_preference.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit.customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit_address.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit_preference.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/data/repositories/server_shadow.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

const _slotTaken =
    'The customer already has a preference for that day and time.';

/// A record the server refuses is rolled back on the device and never
/// merged by the pull; an edit the server drops as older is marked
/// outdated and shows the server's values (S4, S6, S7).
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
                        'review_reason': null,
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
    // preference.
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
  DriftCustomerPreferenceRepository preferences() =>
      DriftCustomerPreferenceRepository(db, now: () => now);

  Json rejectAll(String entity, Json r) => {
    'uuid': r['uuid'],
    'status': 'rejected',
    'server_id': null,
    'error': _slotTaken,
  };

  Json outdatedAll(String entity, Json r) => {
    'uuid': r['uuid'],
    'status': 'outdated',
    'server_id': r['server_id'],
    'review_reason': null,
  };

  List<Json> recordsIn(Json body, String key) => [
    for (final r in body[key] as List) Map<String, dynamic>.from(r as Map),
  ];

  Future<List<CustomerPreferenceTableData>> thursday() => (db.select(
    db.customerPreferenceTable,
  )..where((t) => t.dayOfWeek.equals(4))).get();

  Future<CustomerPreferenceTableData> preference(String id) => (db.select(
    db.customerPreferenceTable,
  )..where((t) => t.customerPreferenceId.equals(id))).getSingle();

  Future<CustomerTableData> customer(String id) => (db.select(
    db.customerTable,
  )..where((t) => t.customerId.equals(id))).getSingle();

  Future<CustomerAddressTableData> address(String id) => (db.select(
    db.customerAddressTable,
  )..where((t) => t.addressId.equals(id))).getSingle();

  Future<PendingChange?> latest(PendingEntity entity, String id) =>
      queue.watchLatestFor(entity, id).first;

  Json serverPreference(
    int id, {
    String? clientUuid,
    int day = 4,
    String start = '14:00:00',
    String end = '15:00:00',
  }) => {
    'id': id,
    'client_uuid': clientUuid,
    'customer_id': 10,
    'day_of_week': day,
    'time_window_start': start,
    'time_window_end': end,
    'enabled': true,
  };

  Future<void> editPreference(String id, PreferenceDetails details) =>
      EditPreferenceUseCase(
        preferenceRepo: preferences(),
        transaction: runner(db),
      ).execute(preferenceId: id, details: details);

  Future<void> editCustomer({
    String? phone = '3874001122',
    String? visualReference = 'Porton verde',
  }) =>
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
          visualReference: visualReference,
        ),
      );

  group('S6: a preference added offline in a slot the office took', () {
    test('is deleted on rejection, keeps the reason and the rejected day and '
        'times, and the pull then stores the server row 58', () async {
      final id =
          await AddPreferenceUseCase(
            preferenceRepo: preferences(),
            transaction: runner(db),
          ).execute(
            customerId: 'c-1',
            details: const PreferenceDetails(
              dayOfWeek: 4,
              start: '14:00',
              end: '16:00',
            ),
          );
      answer = rejectAll;

      await engine.push();

      expect(await thursday(), isEmpty);
      final rejected = (await queue.getRejected()).single;
      expect(rejected.entityId, id);
      expect(rejected.rejectionReason, _slotTaken);
      expect(rejected.payload?[PendingChange.rejectedValuesKey], {
        'day_of_week': 4,
        'time_window_start': '14:00',
        'time_window_end': '16:00',
        'enabled': true,
      });
      expect(rejected.rollback, RejectionRollback.deleted);

      pullRows = {
        'customer_preferences': [serverPreference(58)],
      };
      await sync.pull();

      final stored = (await thursday()).single;
      expect(stored.serverId, 58);
      expect(stored.timeWindowStart, '14:00');
      expect(stored.timeWindowEnd, '15:00');
      expect(stored.customerPreferenceId, isNot(id));
      expect((await queue.getRejected()).single.status, PendingStatus.rejected);
    });

    test('a later edit of the pulled row pushes the server times, never the '
        'rejected 16:00', () async {
      await AddPreferenceUseCase(
        preferenceRepo: preferences(),
        transaction: runner(db),
      ).execute(
        customerId: 'c-1',
        details: const PreferenceDetails(
          dayOfWeek: 4,
          start: '14:00',
          end: '16:00',
        ),
      );
      answer = rejectAll;
      await engine.push();
      pullRows = {
        'customer_preferences': [serverPreference(58)],
      };
      await sync.pull();
      answer = null;

      await preferences().disable(
        (await thursday()).single.customerPreferenceId,
      );
      await engine.push();

      final record = recordsIn(pushBodies.last, 'customer_preferences').single;
      expect(record['server_id'], 58);
      expect(record['time_window_start'], '14:00');
      expect(record['time_window_end'], '15:00');
      expect(record['enabled'], false);
    });

    test('a rejected local row left by an older version is never adopted by '
        'the pull (APP-29)', () async {
      await db
          .into(db.customerPreferenceTable)
          .insert(
            CustomerPreferenceTableCompanion.insert(
              customerPreferenceId: const drift.Value('p-old'),
              customerId: const drift.Value('c-1'),
              dayOfWeek: const drift.Value(4),
              timeWindowStart: '14:00',
              timeWindowEnd: const drift.Value('16:00'),
            ),
          );
      await queue.enqueue(
        entity: PendingEntity.customerPreference,
        entityId: 'p-old',
        action: PendingAction.insert,
      );
      await queue.markRejected(
        (await queue.getPending()).single.id,
        _slotTaken,
      );
      pullRows = {
        'customer_preferences': [serverPreference(58)],
      };

      await sync.pull();

      expect((await preference('p-old')).serverId, isNull);
      expect((await preference('p-old')).timeWindowEnd, '16:00');
      final linked = (await thursday()).where((p) => p.serverId == 58).single;
      expect(linked.timeWindowEnd, '15:00');
    });
  });

  test('a rejected address left by an older version is never adopted by a '
      'server address without client uuid (APP-29)', () async {
    await db
        .into(db.customerAddressTable)
        .insert(
          CustomerAddressTableCompanion.insert(
            addressId: const drift.Value('a-old'),
            customerId: const drift.Value('c-1'),
            street: const drift.Value('Rechazada 1'),
            createdAt: drift.Value(longAgo.subtract(const Duration(days: 1))),
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.customerAddress,
      entityId: 'a-old',
      action: PendingAction.insert,
    );
    await queue.markRejected((await queue.getPending()).single.id, 'invalid');
    pullRows = {
      'customer_addresses': [
        {
          'id': 300,
          'client_uuid': null,
          'customer_id': 10,
          'street': 'Oficina 9',
          'is_primary': false,
          'enabled': true,
        },
      ],
    };

    await sync.pull();

    expect((await address('a-old')).serverId, isNull);
    expect((await address('a-old')).street, 'Rechazada 1');
  });

  test('an edit the server rejects is restored from the last server values '
      'and records what was rejected', () async {
    await editPreference(
      'p-1',
      const PreferenceDetails(dayOfWeek: 5, start: '10:00', end: '13:30'),
    );
    answer = rejectAll;

    await engine.push();

    final row = await preference('p-1');
    expect(row.dayOfWeek, 1);
    expect(row.timeWindowStart, '09:00');
    expect(row.timeWindowEnd, '12:00');
    expect(row.serverId, 201);
    final rejected = (await queue.getRejected()).single;
    expect(rejected.rejectionReason, _slotTaken);
    expect(rejected.payload?[PendingChange.rejectedValuesKey], {
      'day_of_week': 5,
      'time_window_start': '10:00',
      'time_window_end': '13:30',
      'enabled': true,
    });
    expect(rejected.rollback, RejectionRollback.restored);
  });

  test('a rejected customer edit restores the customer and the address it '
      'carried, and records only the fields it changed', () async {
    await editCustomer(phone: '111', visualReference: 'Porton AZUL');
    answer = rejectAll;

    await engine.push();

    expect((await customer('c-1')).phone, '3874001122');
    expect((await address('a-1')).visualReference, 'Porton verde');
    final rejected = (await queue.getRejected()).single;
    expect(rejected.payload?[PendingChange.rejectedValuesKey], {
      'phone_number': '111',
      'address.visual_reference': 'Porton AZUL',
    });
    expect(rejected.rollback, RejectionRollback.restored);
  });

  test('a rejected edit whose row has no server values left stays as it is '
      'and says so', () async {
    // Queued by an older version, before any server values were kept.
    await (db.update(
      db.customerPreferenceTable,
    )..where((t) => t.customerPreferenceId.equals('p-1'))).write(
      const CustomerPreferenceTableCompanion(dayOfWeek: drift.Value(6)),
    );
    await queue.enqueue(
      entity: PendingEntity.customerPreference,
      entityId: 'p-1',
      action: PendingAction.update,
    );
    answer = rejectAll;

    await engine.push();

    expect((await preference('p-1')).dayOfWeek, 6);
    expect((await queue.getRejected()).single.rollback, RejectionRollback.kept);
  });

  test('an edit answered outdated is marked outdated, shows the server '
      'values again and is not sent again', () async {
    await editCustomer(phone: '111');
    await EditAddressUseCase(
      addressRepo: DriftCustomerAddressRepository(db),
      transaction: runner(db),
    ).execute(
      addressId: 'a-1',
      details: const AddressDetails(
        street: 'Belgrano 100',
        neighborhood: 'Centro',
        visualReference: 'Porton AZUL',
      ),
    );
    answer = outdatedAll;

    // The customer waits for its address change, so it goes second.
    await engine.push();
    await engine.push();

    expect((await customer('c-1')).phone, '3874001122');
    expect((await address('a-1')).visualReference, 'Porton verde');
    expect(
      (await latest(PendingEntity.customer, 'c-1'))?.status,
      PendingStatus.outdated,
    );
    expect(
      (await latest(PendingEntity.customerAddress, 'a-1'))?.status,
      PendingStatus.outdated,
    );
    final status = await engine.status();
    expect(status.pendingCount, 0);
    expect(status.rejectedCount, 0);

    await engine.push();
    expect(pushBodies.expand((b) => b.keys), [
      'customer_addresses',
      'customers',
    ]);
  });

  test('an outdated answer links the server id it carries', () async {
    await db
        .into(db.customerPreferenceTable)
        .insert(
          CustomerPreferenceTableCompanion.insert(
            customerPreferenceId: const drift.Value('p-new'),
            customerId: const drift.Value('c-1'),
            dayOfWeek: const drift.Value(3),
            timeWindowStart: '08:00',
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.customerPreference,
      entityId: 'p-new',
      action: PendingAction.insert,
    );
    answer = (entity, r) => {
      'uuid': r['uuid'],
      'status': 'outdated',
      'server_id': 77,
      'review_reason': null,
    };

    await engine.push();

    expect((await preference('p-new')).serverId, 77);
    expect(
      (await latest(PendingEntity.customerPreference, 'p-new'))?.status,
      PendingStatus.outdated,
    );
  });

  test('a pull that skips an edited row keeps its newer server values, so a '
      'rejection restores those', () async {
    await editPreference(
      'p-1',
      const PreferenceDetails(dayOfWeek: 5, start: '10:00', end: '13:30'),
    );
    pullRows = {
      'customer_preferences': [
        serverPreference(201, day: 1, start: '08:00:00', end: '11:00:00'),
      ],
    };
    await sync.pull();
    expect((await preference('p-1')).dayOfWeek, 5);
    answer = rejectAll;

    await engine.push();

    final row = await preference('p-1');
    expect(row.dayOfWeek, 1);
    expect(row.timeWindowStart, '08:00');
    expect(row.timeWindowEnd, '11:00');
  });

  test('an accepted edit forgets the server values it kept', () async {
    final shadow = ServerShadow(db);
    await editPreference(
      'p-1',
      const PreferenceDetails(dayOfWeek: 5, start: '10:00', end: '13:30'),
    );
    expect(await shadow.read(PendingEntity.customerPreference, 'p-1'), {
      'day_of_week': 1,
      'time_window_start': '09:00',
      'time_window_end': '12:00',
      'enabled': true,
    });

    await engine.push();

    expect(await shadow.read(PendingEntity.customerPreference, 'p-1'), isNull);
    expect((await preference('p-1')).dayOfWeek, 5);
  });

  test('a second edit before the push keeps the values from before the '
      'first one', () async {
    await editPreference(
      'p-1',
      const PreferenceDetails(dayOfWeek: 5, start: '10:00', end: '13:30'),
    );
    await editPreference(
      'p-1',
      const PreferenceDetails(dayOfWeek: 6, start: '10:00', end: '13:30'),
    );
    answer = rejectAll;

    await engine.push();

    expect((await preference('p-1')).dayOfWeek, 1);
  });

  group('a customer created offline and rejected', () {
    Future<void> createCustomer() => DriftCustomerRepository(db).saveCustomer(
      Customer(
        id: 'c-new',
        name: 'Nuevo',
        addresses: [
          CustomerAddress(id: 'a-new', street: 'Mitre 50', isPrimary: true),
        ],
        preferences: const [],
      ),
    );

    Future<int> count(String id) async => (await (db.select(
      db.customerTable,
    )..where((t) => t.customerId.equals(id))).get()).length;

    test('is deleted with its address when nothing references it', () async {
      await createCustomer();
      answer = rejectAll;

      await engine.push();

      expect(await count('c-new'), 0);
      expect(
        await (db.select(
          db.customerAddressTable,
        )..where((t) => t.customerId.equals('c-new'))).get(),
        isEmpty,
      );
      final rejected = (await queue.getRejected()).single;
      expect(rejected.rollback, RejectionRollback.deleted);
      expect(
        (rejected.payload?[PendingChange.rejectedValuesKey] as Map)['name'],
        'Nuevo',
      );
    });

    test('is kept when a sale references it', () async {
      await createCustomer();
      await db
          .into(db.saleTable)
          .insert(
            SaleTableCompanion.insert(
              saleId: const drift.Value('s-1'),
              customerId: 'c-new',
              totalAmount: 100,
              paymentMethod: 'cash',
              quantity: 1,
              shipping_amount: 0,
            ),
          );
      answer = (entity, r) =>
          entity == 'customers' ? rejectAll(entity, r) : null;

      await engine.push();

      expect(await count('c-new'), 1);
      expect(
        (await queue.getRejected())
            .where((c) => c.entity == PendingEntity.customer)
            .single
            .rollback,
        RejectionRollback.kept,
      );
    });
  });
}
