import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/pull/preference_applier.dart';
import 'package:app/features/sync/pull/pull_applier.dart' show Json;

import 'pull_support.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = memoryDatabase();
    await seedCustomer(db, id: 'cust-1', serverId: 11);
  });
  tearDown(() => db.close());

  Future<void> local(
    String id, {
    int day = 1,
    String start = '09:00',
    String? end = '12:00',
    int? serverId,
  }) => db
      .into(db.customerPreferenceTable)
      .insert(
        CustomerPreferenceTableCompanion.insert(
          customerPreferenceId: Value(id),
          customerId: const Value('cust-1'),
          dayOfWeek: Value(day),
          timeWindowStart: start,
          timeWindowEnd: Value(end),
          serverId: Value(serverId),
        ),
      );

  Json server(
    int id, {
    String? clientUuid,
    int day = 1,
    String? start = '09:00:00',
    String? end = '13:00:00',
    bool enabled = true,
  }) => {
    'id': id,
    'client_uuid': clientUuid,
    'customer_id': 11,
    'day_of_week': day,
    'time_window_start': start,
    'time_window_end': end,
    'enabled': enabled,
  };

  Future<void> pull(List<Json> rows) async => PreferenceApplier(
    db,
  ).applyChanges({'customer_preferences': rows}, await pullContext(db));

  Future<List<CustomerPreferenceTableData>> rows() => (db.select(
    db.customerPreferenceTable,
  )..orderBy([(t) => OrderingTerm.asc(t.customerPreferenceId)])).get();

  test('links a preference pushed from the device by its client uuid and '
      'takes the server values as H:i', () async {
    await local('p-1');

    await pull([server(500, clientUuid: 'p-1', day: 2, end: '13:30:00')]);

    final stored = (await rows()).single;
    expect(stored.customerPreferenceId, 'p-1');
    expect(stored.serverId, 500);
    expect(stored.dayOfWeek, 2);
    expect(stored.timeWindowStart, '09:00');
    expect(stored.timeWindowEnd, '13:30');
  });

  test('updates a linked preference by its server id', () async {
    await local('p-1', serverId: 500);

    await pull([server(500, enabled: false)]);

    final stored = (await rows()).single;
    expect(stored.customerPreferenceId, 'p-1');
    expect(stored.enabled, isFalse);
    expect(stored.timeWindowEnd, '13:00');
  });

  test(
    'a new server preference keeps its client uuid as the local id',
    () async {
      await pull([server(500, clientUuid: 'from-other-phone')]);

      final stored = (await rows()).single;
      expect(stored.customerPreferenceId, 'from-other-phone');
      expect(stored.serverId, 500);
    },
  );

  test('a web preference on the same day and start as an unlinked local one '
      'is linked to it instead of duplicated', () async {
    await local('p-1');

    await pull([server(500)]);

    final stored = (await rows()).single;
    expect(stored.customerPreferenceId, 'p-1');
    expect(stored.serverId, 500);
  });

  test('a preference with an unsent change keeps its local values and still '
      'gets linked', () async {
    await local('p-1', day: 4, start: '15:00', end: '18:00');
    await enqueueUnsent(db, PendingEntity.customerPreference, 'p-1');

    await pull([server(500, clientUuid: 'p-1', day: 2)]);

    final stored = (await rows()).single;
    expect(stored.serverId, 500);
    expect(stored.dayOfWeek, 4);
    expect(stored.timeWindowStart, '15:00');
    expect(stored.timeWindowEnd, '18:00');
  });

  test('a null start is stored as the no-start time', () async {
    await pull([server(500, day: 0, start: null, end: null)]);

    final stored = (await rows()).single;
    expect(stored.dayOfWeek, 0);
    expect(stored.timeWindowStart, '00:00');
    expect(stored.timeWindowEnd, isNull);
  });

  test('pulling the same rows twice never duplicates', () async {
    await local('p-1');
    final page = [server(500, clientUuid: 'p-1'), server(501, day: 3)];

    await pull(page);
    await pull(page);

    expect(await rows(), hasLength(2));
  });

  test('the bootstrap links by client uuid too', () async {
    await local('p-1');

    await PreferenceApplier(db).applyForCustomer('cust-1', [
      server(500, clientUuid: 'p-1'),
    ], await bootstrapContext(db));

    final stored = (await rows()).single;
    expect(stored.customerPreferenceId, 'p-1');
    expect(stored.serverId, 500);
  });
}
