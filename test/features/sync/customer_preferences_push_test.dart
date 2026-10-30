import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer_preference.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/customers/domain/usecases/add_preference.usecase.dart';
import 'package:app/features/customers/domain/usecases/create.customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/disable_preference.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit_preference.usecase.dart';
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
    for (final (id, day, start, end, serverId) in [
      ('p-1', 1, '09:00', '12:00', 101),
      ('p-0', 0, '00:00', null, 102),
    ]) {
      await db
          .into(db.customerPreferenceTable)
          .insert(
            CustomerPreferenceTableCompanion.insert(
              customerPreferenceId: drift.Value(id),
              customerId: const drift.Value('c-1'),
              dayOfWeek: drift.Value(day),
              timeWindowStart: start,
              timeWindowEnd: drift.Value(end),
              serverId: drift.Value(serverId),
              createdAt: drift.Value(longAgo),
              lastModifiedDate: drift.Value(longAgo),
            ),
          );
    }
  });
  tearDown(() => db.close());

  DriftCustomerPreferenceRepository repo() =>
      DriftCustomerPreferenceRepository(db, now: () => now);
  final runner = driftTransactionRunner;

  List<Json> recordsIn(Json body, String key) => [
    for (final r in body[key] as List) Map<String, dynamic>.from(r as Map),
  ];

  Future<CustomerPreferenceTableData> row(String id) => (db.select(
    db.customerPreferenceTable,
  )..where((t) => t.customerPreferenceId.equals(id))).getSingle();

  test(
    'an edited preference travels under customer_preferences with exactly '
    'the contract fields, H:i times, a strict bool and a UTC modified_at',
    () async {
      await EditPreferenceUseCase(
        preferenceRepo: repo(),
        transaction: runner(db),
      ).execute(
        preferenceId: 'p-1',
        details: const PreferenceDetails(
          dayOfWeek: 5,
          start: '10:00',
          end: '13:30',
        ),
      );

      await engine.push();

      final body = pushBodies.single;
      expect(body.keys, ['customer_preferences']);
      final record = recordsIn(body, 'customer_preferences').single;
      expect(record, {
        'uuid': 'p-1',
        'server_id': 101,
        'customer_id': 10,
        'day_of_week': 5,
        'time_window_start': '10:00',
        'time_window_end': '13:30',
        'enabled': true,
        'modified_at': now.toUtc().toIso8601String(),
      });
      expect(record['enabled'], isA<bool>());
      expect(record['modified_at'], endsWith('Z'));
      expect(await queue.countPending(), 0);
    },
  );

  test('an added preference has no server_id until the server accepts it, '
      'then stores it', () async {
    final id =
        await AddPreferenceUseCase(
          preferenceRepo: repo(),
          transaction: runner(db),
        ).execute(
          customerId: 'c-1',
          details: const PreferenceDetails(dayOfWeek: 3, start: '09:00'),
        );

    await engine.push();

    final record = recordsIn(pushBodies.single, 'customer_preferences').single;
    expect(record['uuid'], id);
    expect(record.containsKey('server_id'), isFalse);
    expect(record['time_window_end'], isNull);
    expect(record['enabled'], true);
    expect((await row(id)).serverId, 901);
    expect(await queue.countPending(), 0);
  });

  test('a disabled preference travels with enabled false', () async {
    await DisablePreferenceUseCase(
      preferenceRepo: repo(),
      transaction: runner(db),
    ).execute('p-1');

    await engine.push();

    final record = recordsIn(pushBodies.single, 'customer_preferences').single;
    expect(record['uuid'], 'p-1');
    expect(record['enabled'], false);
    expect(record['time_window_start'], '09:00');
  });

  test('a preference stored without a start (a server row with a null '
      'start) travels with a null start', () async {
    await DisablePreferenceUseCase(
      preferenceRepo: repo(),
      transaction: runner(db),
    ).execute('p-0');

    await engine.push();

    final record = recordsIn(pushBodies.single, 'customer_preferences').single;
    expect(record['day_of_week'], 0);
    expect(record['time_window_start'], isNull);
  });

  test('every change of one preference collapses into one record with its '
      'latest state', () async {
    final edit = EditPreferenceUseCase(
      preferenceRepo: repo(),
      transaction: runner(db),
    );
    await edit.execute(
      preferenceId: 'p-1',
      details: const PreferenceDetails(dayOfWeek: 2, start: '09:00'),
    );
    await edit.execute(
      preferenceId: 'p-1',
      details: const PreferenceDetails(dayOfWeek: 6, start: '09:00'),
    );

    await engine.push();

    final record = recordsIn(pushBodies.single, 'customer_preferences').single;
    expect(record['day_of_week'], 6);
    expect(await queue.countPending(), 0);
  });

  test('a rejected preference keeps the server reason', () async {
    await DisablePreferenceUseCase(
      preferenceRepo: repo(),
      transaction: runner(db),
    ).execute('p-1');
    answer = (entity, r) => {
      'uuid': r['uuid'],
      'status': 'rejected',
      'error': 'The customer already has a preference for that day and time.',
    };

    await engine.push();

    final rejected = await queue.getRejected();
    expect(rejected.single.entity, PendingEntity.customerPreference);
    expect(rejected.single.entityId, 'p-1');
    expect(
      rejected.single.rejectionReason,
      'The customer already has a preference for that day and time.',
    );
    expect((await row('p-1')).serverId, 101);
  });

  test('the preferences of a new customer reference it by uuid, in the same '
      'push after the customer and its addresses', () async {
    await CreateCustomerUseCase(
      customerRepository: DriftCustomerRepository(db),
      transaction: runner(db),
    ).execute(
      Customer(
        id: 'c-new',
        name: 'Nuevo',
        addresses: [
          CustomerAddress(id: 'a-new', street: 'Mitre 50', isPrimary: true),
        ],
        preferences: [
          CustomerPreference(
            id: 'np-1',
            dayOfWeek: 1,
            timeWindowStart: '09:00',
            timeWindowEnd: '12:00',
          ),
          CustomerPreference(
            id: 'np-2',
            dayOfWeek: 6,
            timeWindowStart: '09:00',
            timeWindowEnd: '13:00',
          ),
        ],
      ),
    );

    await engine.push();

    final body = pushBodies.single;
    expect(body.keys.toList(), ['customers', 'customer_preferences']);
    final records = recordsIn(body, 'customer_preferences');
    expect([for (final r in records) r['uuid']], ['np-1', 'np-2']);
    for (final r in records) {
      expect(r['customer_uuid'], 'c-new');
      expect(r.containsKey('customer_id'), isFalse);
      expect(r['enabled'], true);
    }
    expect(records.last['time_window_end'], '13:00');
    expect((await row('np-1')).serverId, isNotNull);
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
      'sales',
      'container_movements',
      'payments',
      'sale_cancellations',
      'payment_cancellations',
    ];
    expect(keys, [
      for (final k in serverOrder)
        if (keys.contains(k)) k,
    ]);
    expect(keys, contains('customer_preferences'));
    expect(
      keys.indexOf('customer_preferences'),
      keys.indexOf('customer_addresses') + 1,
    );
  });
}
