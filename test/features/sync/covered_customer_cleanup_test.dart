import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/removed_customers.dart';
import 'package:app/features/sync/data/repositories/server_shadow.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/push/entity_pusher.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

/// Local clock of every test: the cover day of the stops on [_today].
DateTime _now() => DateTime(2026, 11, 12, 10);
const _today = '2026-11-12';
const _yesterday = '2026-11-11';

/// Sends each queued sale as `{uuid}`; enough to settle it or keep it
/// pending depending on the fake server's answer.
class _SalePusher implements EntityPusher {
  @override
  PendingEntity get entity => PendingEntity.sale;

  @override
  String get wireKey => 'sales';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async => PushPlan(
    records: [
      for (final c in changes)
        PushRecord(
          uuid: c.entityId,
          body: {'uuid': c.entityId},
          changeIds: [c.id],
        ),
    ],
  );

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {}
}

class _FakeServer {
  final List<Map<String, dynamic>> pushBodies = [];
  bool acceptSales = true;
  bool offline = false;

  Future<ResponseBody> handle(RequestOptions options) async {
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'no network',
      );
    }
    switch (options.path) {
      case '/sync/pull':
        return FakeHttpAdapter.json(200, {
          'data': <String, dynamic>{},
          'meta': {
            'page': 1,
            'per_page': 200,
            'is_last_page': true,
            'until': '2026-11-12T13:00:00+00:00',
            'cursor': '2026-11-12T12:59:55+00:00',
          },
          'message': null,
        });
      case '/sync/push':
        final body = Map<String, dynamic>.from(options.data as Map);
        pushBodies.add(body);
        return FakeHttpAdapter.json(200, {
          'data': {
            'sales': [
              if (acceptSales)
                for (final r in (body['sales'] as List? ?? const []))
                  {
                    'uuid': (r as Map)['uuid'],
                    'status': 'accepted',
                    'server_id': 900,
                  },
            ],
          },
          'message': null,
        });
    }
    throw StateError('Unexpected request ${options.path}');
  }
}

void main() {
  late AppDatabase db;
  late _FakeServer server;
  late SyncEngine engine;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(server.handle);
    engine = SyncEngine(
      dio: dio,
      db: db,
      sync: SyncService(dio, db, today: _now),
      pushers: [_SalePusher()],
      now: _now,
    );
    // The day is already downloaded: every cycle pushes and then pulls.
    await db
        .into(db.syncStateTable)
        .insert(
          SyncStateTableCompanion.insert(
            key: SyncService.pullCursorKey,
            value: '2026-11-12T08:00:00+00:00',
          ),
        );
    for (final (id, date) in [('r-today', _today), ('r-old', _yesterday)]) {
      await db
          .into(db.routeTable)
          .insert(
            RouteTableCompanion.insert(routeId: Value(id), route_date: date),
          );
    }
  });
  tearDown(() => db.close());

  /// A customer with one row in every table that belongs to it, on a stop
  /// of [routeId] (none when null), and the sync_state keys kept for it.
  Future<void> seedCustomer(
    String id, {
    required bool isCover,
    List<String> routeIds = const ['r-old'],
  }) async {
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: Value(id),
            name: 'Customer $id',
            isCover: Value(isCover),
          ),
        );
    await db
        .into(db.customerAddressTable)
        .insert(
          CustomerAddressTableCompanion.insert(
            addressId: Value('addr-$id'),
            customerId: Value(id),
            street: const Value('Mitre 10'),
            isPrimary: const Value(true),
          ),
        );
    await db
        .into(db.customerPreferenceTable)
        .insert(
          CustomerPreferenceTableCompanion.insert(
            customerPreferenceId: Value('pref-$id'),
            customerId: Value(id),
            timeWindowStart: '09:00',
          ),
        );
    await db
        .into(db.customerAgreementTable)
        .insert(
          CustomerAgreementTableCompanion.insert(
            agreementId: Value('agr-$id'),
            customerId: id,
            productId: 'p-1',
            unitPrice: 100,
            validFrom: _yesterday,
          ),
        );
    for (final routeId in routeIds) {
      await db
          .into(db.routeStopTable)
          .insert(
            RouteStopTableCompanion.insert(
              routeStopId: Value('stop-$id-$routeId'),
              routeId: routeId,
              customerId: id,
              customerAddressId: Value('addr-$id'),
              sequence: 1,
              scheduledAt: _now(),
              isCover: Value(isCover),
            ),
          );
    }
    await db
        .into(db.visitTable)
        .insert(
          VisitTableCompanion.insert(
            visitId: Value('visit-$id'),
            routeStopId:
                'stop-$id-${routeIds.isEmpty ? 'none' : routeIds.first}',
            customerId: id,
            visitType: 'DELIVERY',
            arrived_at: _now(),
          ),
        );
    await db
        .into(db.saleTable)
        .insert(
          SaleTableCompanion.insert(
            saleId: Value('sale-$id'),
            customerId: id,
            totalAmount: 200,
            paymentMethod: 'cash',
            quantity: 2,
            shipping_amount: 0,
            visitId: Value('visit-$id'),
          ),
        );
    await db
        .into(db.saleItemTable)
        .insert(
          SaleItemTableCompanion.insert(
            saleItemId: Value('item-$id'),
            saleId: 'sale-$id',
            productId: 'p-1',
            quantity: 2,
            unitPrice: 100,
            subtotal: 200,
          ),
        );
    await db
        .into(db.paymentTable)
        .insert(
          PaymentTableCompanion.insert(
            paymentId: Value('pay-$id'),
            customerId: id,
            amount: 200,
            paymentMethod: 'EFECTIVO',
            saleId: Value('sale-$id'),
          ),
        );
    await db
        .into(db.customerAccountEntryTable)
        .insert(
          CustomerAccountEntryTableCompanion.insert(
            customerAccountEntryId: Value('entry-$id'),
            customerId: id,
            entryType: 'SALE',
            amount: 200,
            direction: 1,
          ),
        );
    await db
        .into(db.customerBalanceTable)
        .insert(CustomerBalanceTableCompanion.insert(customerId: id));
    await db
        .into(db.containerMovementTable)
        .insert(
          ContainerMovementTableCompanion.insert(
            containerMovementId: Value('mov-$id'),
            customerId: id,
            containerType: 'BIDON_20',
            deliveredQuantity: 1,
            returnedQuantity: 0,
          ),
        );
    await db
        .into(db.customerContainerBalanceTable)
        .insert(
          CustomerContainerBalanceTableCompanion.insert(
            customerId: id,
            containerType: 'BIDON_20',
          ),
        );
    for (final key in [
      ServerShadow.keyOf(PendingEntity.customer, id),
      ServerShadow.keyOf(PendingEntity.customerAddress, 'addr-$id'),
      ServerShadow.keyOf(PendingEntity.customerPreference, 'pref-$id'),
    ]) {
      await db
          .into(db.syncStateTable)
          .insert(SyncStateTableCompanion.insert(key: key, value: '{}'));
    }
  }

  Future<void> markRemoved(String id) => db
      .into(db.syncStateTable)
      .insert(
        SyncStateTableCompanion.insert(
          key: RemovedCustomers.keyOf(id),
          value: '2026-11-12T09:00:00+00:00',
        ),
      );

  Future<int> queueChange(
    PendingEntity entity,
    String entityId,
    PendingStatus status,
  ) => db
      .into(db.pendingChangeTable)
      .insert(
        PendingChangeTableCompanion.insert(
          entity: entity.wireName,
          entityId: entityId,
          action: PendingAction.insert.wireName,
          status: Value(status.wireName),
        ),
      );

  /// Rows of [id] in every table the cleanup clears, by table.
  Future<Map<String, int>> rowsOf(String id) async {
    Future<int> count(String sql) async =>
        (await db.customSelect(sql).getSingle()).read<int>('n');
    return {
      'customers': await count(
        "SELECT COUNT(*) AS n FROM customers WHERE customer_id = '$id'",
      ),
      for (final table in [
        'customer_addresses',
        'customer_preferences',
        'customer_agreements',
        'route_stops',
        'visits',
        'sales',
        'payments',
        'customer_account_entries',
        'customer_balances',
        'container_movements',
        'customer_container_balances',
      ])
        table: await count(
          "SELECT COUNT(*) AS n FROM $table WHERE customer_id = '$id'",
        ),
      'sale_items': await count(
        "SELECT COUNT(*) AS n FROM sale_items WHERE sale_id = 'sale-$id'",
      ),
      'sync_state': await count(
        'SELECT COUNT(*) AS n FROM sync_state WHERE '
        "key IN ('removed_customer:$id', 'shadow:customer:$id', "
        "'shadow:customer_address:addr-$id', "
        "'shadow:customer_preference:pref-$id')",
      ),
    };
  }

  Matcher allGone() => everyElement(0);

  /// Whether [id] still has its rows in every table; its sync_state keys
  /// are left out, since a cycle forgets settled shadows on its own.
  Future<bool> keepsEveryRow(String id) async {
    final rows = await rowsOf(id)
      ..remove('sync_state');
    return rows.values.every((n) => n >= 1);
  }

  Future<List<PendingChangeTableData>> queueRows() =>
      db.select(db.pendingChangeTable).get();

  test(
    'a covered customer whose cover day ended and whose records are settled '
    'is forgotten with every row of its own, without telling the server',
    () async {
      await seedCustomer('cov', isCover: true);

      final status = await engine.runCycle();

      expect(status.lastResult, SyncCycleResult.success);
      expect((await rowsOf('cov')).values, allGone());
      // S8: nothing enqueued, nothing sent.
      expect(await queueRows(), isEmpty);
      expect(server.pushBodies, isEmpty);
    },
  );

  test(
    'settled queue rows of the customer go with it; other rows stay',
    () async {
      await seedCustomer('cov', isCover: true);
      await seedCustomer('own', isCover: false);
      await queueChange(PendingEntity.sale, 'sale-cov', PendingStatus.sent);
      await queueChange(
        PendingEntity.visit,
        'visit-cov',
        PendingStatus.outdated,
      );
      await queueChange(
        PendingEntity.payment,
        'pay-cov',
        PendingStatus.dismissed,
      );
      await queueChange(PendingEntity.sale, 'sale-own', PendingStatus.sent);

      await engine.runCycle();

      expect((await rowsOf('cov')).values, allGone());
      expect((await queueRows()).map((r) => r.entityId), ['sale-own']);
      expect(server.pushBodies, isEmpty);
    },
  );

  test('other customers keep every row, untouched', () async {
    await seedCustomer('cov', isCover: true);
    await seedCustomer('own', isCover: false);
    await seedCustomer('cov-today', isCover: true, routeIds: ['r-today']);
    final ownBefore = await (db.select(
      db.customerTable,
    )..where((t) => t.customerId.equals('own'))).getSingle();

    await engine.runCycle();

    expect((await rowsOf('cov')).values, allGone());
    for (final id in ['own', 'cov-today']) {
      expect(await keepsEveryRow(id), isTrue, reason: id);
    }
    expect(
      await (db.select(
        db.customerTable,
      )..where((t) => t.customerId.equals('own'))).getSingle(),
      ownBefore,
    );
  });

  test('a covered customer is kept while today is its cover day', () async {
    await seedCustomer('cov', isCover: true, routeIds: ['r-old', 'r-today']);

    await engine.runCycle();

    expect((await rowsOf('cov'))['customers'], 1);
    expect((await rowsOf('cov'))['route_stops'], 2);
  });

  test('a covered customer with no stops left counts as ended', () async {
    await seedCustomer('cov', isCover: true, routeIds: const []);

    await engine.runCycle();

    expect((await rowsOf('cov')).values, allGone());
  });

  test('a pending sale keeps the customer until the push accepts it; the next '
      'cycle forgets it', () async {
    await seedCustomer('cov', isCover: true);
    await queueChange(PendingEntity.sale, 'sale-cov', PendingStatus.pending);
    server.acceptSales = false;

    await engine.runCycle();

    expect((await rowsOf('cov'))['customers'], 1);
    expect((await rowsOf('cov'))['sales'], 1);
    expect((await queueRows()).single.status, 'pending');

    server.acceptSales = true;
    await engine.runCycle();

    expect((await rowsOf('cov')).values, allGone());
    expect(await queueRows(), isEmpty);
  });

  for (final (entity, entityId) in [
    (PendingEntity.visit, 'visit-cov'),
    (PendingEntity.customerAddress, 'addr-cov'),
    (PendingEntity.routeStop, 'stop-cov-r-old'),
    (PendingEntity.containerMovement, 'mov-cov'),
    (PendingEntity.paymentCancellation, 'pay-cov'),
  ]) {
    test('a rejected ${entity.wireName} keeps the customer', () async {
      await seedCustomer('cov', isCover: true);
      await queueChange(entity, entityId, PendingStatus.rejected);

      await engine.runCycle();

      expect(await keepsEveryRow('cov'), isTrue);
      expect((await queueRows()).single.status, 'rejected');
    });
  }

  test('a change awaiting approval keeps the customer', () async {
    await seedCustomer('cov', isCover: true);
    await markRemoved('cov');
    await queueChange(
      PendingEntity.customerPreference,
      'pref-cov',
      PendingStatus.awaitingApproval,
    );

    await engine.runCycle();

    expect((await rowsOf('cov'))['customers'], 1);
  });

  test('a covered customer listed in customers_removed is forgotten on its '
      'cover day once settled', () async {
    await seedCustomer('cov', isCover: true, routeIds: ['r-today']);
    await markRemoved('cov');

    await engine.runCycle();

    expect((await rowsOf('cov')).values, allGone());
  });

  test('a removed covered customer with something pending is kept', () async {
    await seedCustomer('cov', isCover: true, routeIds: ['r-today']);
    await markRemoved('cov');
    server.acceptSales = false;
    await queueChange(PendingEntity.sale, 'sale-cov', PendingStatus.pending);

    await engine.runCycle();

    expect((await rowsOf('cov'))['customers'], 1);
  });

  test('an own customer is never forgotten, even with old stops and listed in '
      'customers_removed', () async {
    await seedCustomer('own', isCover: false);
    await markRemoved('own');

    await engine.runCycle();

    expect(await keepsEveryRow('own'), isTrue);
  });

  test('a cleanup failure keeps the cycle successful, leaves every row in '
      'place and is retried on the next cycle', () async {
    await seedCustomer('cov', isCover: true);
    await db.customStatement(
      'CREATE TRIGGER fail_customer_delete BEFORE DELETE ON customers '
      "BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );

    final failed = await engine.runCycle();

    expect(failed.lastResult, SyncCycleResult.success);
    expect(failed.lastError, isNull);
    expect(await keepsEveryRow('cov'), isTrue);

    await db.customStatement('DROP TRIGGER fail_customer_delete');
    await engine.runCycle();

    expect((await rowsOf('cov')).values, allGone());
  });

  test('an offline cycle skips the cleanup', () async {
    await seedCustomer('cov', isCover: true);
    server.offline = true;

    final status = await engine.runCycle();

    expect(status.lastResult, SyncCycleResult.offline);
    expect((await rowsOf('cov'))['customers'], 1);
  });
}
