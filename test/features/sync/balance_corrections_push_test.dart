import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/balance_corrections/data/repositories/balance_correction.repository.dart';
import 'package:app/features/balance_corrections/domain/models/balance_correction.dart';
import 'package:app/features/balance_corrections/domain/usecases/correct_balance.usecase.dart';
import 'package:app/features/inventory/data/repositories/custody.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/pull/pull_applier.dart' show dateOnly;
import 'package:app/features/sync/push/balance_correction_pusher.dart';
import 'package:app/features/sync/push/container_movement_pusher.dart';
import 'package:app/features/sync/push/payment_cancellation_pusher.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';
import 'package:app/features/visits/data/repositories/drift_visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

const _entities = ['payments', 'payment_cancellations', 'balance_corrections'];

/// Accepts every pushed record unless [answer] says otherwise.
class _FakeServer {
  final List<Json> pushBodies = [];
  Json? Function(String entity, Json record)? answer;
  Map<String, List<Json>> pullRows = {};
  int _nextId = 900;

  Future<ResponseBody> handle(RequestOptions options) async {
    if (options.path == '/sync/pull') {
      return FakeHttpAdapter.json(200, {
        'data': pullRows,
        'meta': {
          'page': 1,
          'per_page': 200,
          'is_last_page': true,
          'until': '2026-11-17T13:00:00+00:00',
          'cursor': '2026-11-17T12:59:55+00:00',
        },
        'message': null,
      });
    }
    final body = Map<String, dynamic>.from(options.data as Map);
    pushBodies.add(body);
    return FakeHttpAdapter.json(200, {
      'data': {
        for (final entity in _entities)
          entity: [
            for (final r in (body[entity] as List? ?? const []))
              answer?.call(entity, Map<String, dynamic>.from(r as Map)) ??
                  {
                    'uuid': (r as Map)['uuid'],
                    'status': 'accepted',
                    'server_id': ++_nextId,
                    'review_reasons': const [],
                  },
          ],
      },
      'message': null,
    });
  }
}

const _wholeContainers =
    'Los envases contados deben ser un número entero mayor o igual a cero.';

void main() {
  late AppDatabase db;
  late _FakeServer server;
  late SyncEngine engine;
  late SyncService sync;
  late PendingChangeRepository queue;
  late DriftPaymentRepository payments;

  // Whole seconds: the database stores dates at that precision.
  final now = DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().millisecondsSinceEpoch ~/ 1000 * 1000,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(server.handle);
    sync = SyncService(dio, db);
    engine = SyncEngine(dio: dio, db: db, sync: sync);
    queue = DriftPendingChangeRepository(db);
    payments = DriftPaymentRepository(db);

    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
            serverId: const drift.Value(10),
          ),
        );
    await db
        .into(db.customerBalanceTable)
        .insert(
          CustomerBalanceTableCompanion.insert(
            customerId: 'c-1',
            currentBalance: const drift.Value(1000),
            serverId: const drift.Value(500),
          ),
        );
    await db
        .into(db.containerTypeTable)
        .insert(
          ContainerTypeTableCompanion.insert(
            id: const drift.Value(3),
            code: 'BIDON_20L',
          ),
        );
    await Custody(db).post('c-1', 'BIDON_20L', 5);
    await db
        .into(db.paymentMethodTable)
        .insert(
          PaymentMethodTableCompanion.insert(
            id: const drift.Value(5),
            code: 'CASH',
            name: 'Cash',
          ),
        );
    await db
        .into(db.routeTable)
        .insert(
          RouteTableCompanion.insert(
            routeId: const drift.Value('r-1'),
            route_date: dateOnly(now),
            serverId: const drift.Value(7),
          ),
        );
    await db
        .into(db.routeStopTable)
        .insert(
          RouteStopTableCompanion.insert(
            routeStopId: const drift.Value('s-1'),
            routeId: 'r-1',
            customerId: 'c-1',
            sequence: 1,
            scheduledAt: now,
            serverId: const drift.Value(70),
          ),
        );
  });
  tearDown(() => db.close());

  Future<BalanceCorrection> correct(
    BalanceTarget target,
    num counted, {
    String? containerType,
    String? visitId,
    String id = 'corr-1',
    String reason = 'Conté en el lugar',
  }) =>
      CorrectBalanceUseCase(
        repo: DriftBalanceCorrectionRepository(db),
        transaction: driftTransactionRunner(db),
        now: () => now,
        newId: () => id,
      ).execute(
        customerId: 'c-1',
        target: target,
        counted: counted,
        reason: reason,
        containerType: containerType,
        visitId: visitId,
      );

  List<Json> sent(String entity) => [
    for (final r in (server.pushBodies.last[entity] as List? ?? const []))
      Map<String, dynamic>.from(r as Map),
  ];

  Future<double> balance() => payments.watchCustomerBalance('c-1').first;

  Future<int> custody([String code = 'BIDON_20L']) =>
      Custody(db).quantityOf('c-1', code);

  Future<PendingChangeTableData> queued(String id) => (db.select(
    db.pendingChangeTable,
  )..where((t) => t.entityId.equals(id))).getSingle();

  Future<BalanceCorrectionTableData> row(String id) => (db.select(
    db.balanceCorrectionTable,
  )..where((t) => t.correctionId.equals(id))).getSingle();

  test('the pusher handles balance_correction as balance_corrections, right '
      'after the payment cancellations', () {
    final pushers = SyncEngine.defaultPushers(db);
    final at = pushers.indexWhere((p) => p is BalanceCorrectionPusher);
    expect(pushers[at].entity, PendingEntity.balanceCorrection);
    expect(pushers[at].wireKey, 'balance_corrections');
    expect(pushers[at - 1], isA<PaymentCancellationPusher>());
  });

  test('a debt correction travels with the counted and the seen balance; '
      'accepted, it keeps its server id and the balance', () async {
    await correct(BalanceTarget.debt, 800.5, reason: '  Pagó y no se cargó ');
    expect(await balance(), 800.5);

    await engine.push();

    final body = sent('balance_corrections').single;
    expect(body, {
      'uuid': 'corr-1',
      'customer_id': 10,
      'target': 'debt',
      'counted': 800.5,
      'seen_balance': 1000.0,
      'reason': 'Pagó y no se cargó',
      'corrected_at': now.toUtc().toIso8601String(),
    });
    expect(body['corrected_at'], endsWith('Z'));
    expect(body['counted'], isA<double>());
    expect(body['seen_balance'], isA<double>());
    expect((await queued('corr-1')).status, 'sent');
    expect((await row('corr-1')).serverId, 901);
    expect(await balance(), 800.5);
  });

  test('a container correction carries the type id and whole counts', () async {
    await correct(BalanceTarget.containers, 3, containerType: 'BIDON_20L');
    expect(await custody(), 3);

    await engine.push();

    final body = sent('balance_corrections').single;
    expect(body, {
      'uuid': 'corr-1',
      'customer_id': 10,
      'target': 'containers',
      'container_type_id': 3,
      'counted': 3,
      'seen_balance': 5,
      'reason': 'Conté en el lugar',
      'corrected_at': now.toUtc().toIso8601String(),
    });
    expect(body['counted'], isA<int>());
    expect(body['seen_balance'], isA<int>());
    expect((await queued('corr-1')).status, 'sent');
    expect(await custody(), 3);
  });

  test('a debt correction never carries a container type', () async {
    await correct(BalanceTarget.debt, 0);

    await engine.push();

    expect(
      sent('balance_corrections').single.containsKey('container_type_id'),
      isFalse,
    );
  });

  test('a rejected correction keeps the server error in the queue and takes '
      'its difference back', () async {
    await correct(BalanceTarget.containers, 2, containerType: 'BIDON_20L');
    await correct(BalanceTarget.debt, 1500, id: 'corr-2');
    expect(await custody(), 2);
    expect(await balance(), 1500);
    server.answer = (entity, r) => {
      'uuid': r['uuid'],
      'status': 'rejected',
      'server_id': null,
      'error': _wholeContainers,
    };

    await engine.push();

    for (final id in ['corr-1', 'corr-2']) {
      final entry = await queued(id);
      expect(entry.status, 'rejected');
      expect(entry.rejectionReason, _wholeContainers);
    }
    expect(await custody(), 5);
    expect(await balance(), 1000);
    expect((await row('corr-1')).serverId, isNull);
  });

  test('an unknown container type is rejected on the device and its '
      'difference taken back', () async {
    await Custody(db).post('c-1', 'SIFON', 4);
    await correct(BalanceTarget.containers, 1, containerType: 'SIFON');
    expect(await custody('SIFON'), 1);

    await engine.push();

    expect(server.pushBodies, isEmpty);
    final entry = await queued('corr-1');
    expect(entry.status, 'rejected');
    expect(entry.rejectionReason, ContainerMovementPusher.unknownType('SIFON'));
    expect(await custody('SIFON'), 4);
  });

  test('a correction no longer on the device is rejected locally', () async {
    await correct(BalanceTarget.debt, 700);
    await (db.delete(db.balanceCorrectionTable)).go();

    await engine.push();

    expect(server.pushBodies, isEmpty);
    final entry = await queued('corr-1');
    expect(entry.status, 'rejected');
    expect(entry.rejectionReason, BalanceCorrectionPusher.missing);
    expect(
      BalanceCorrectionPusher.missing,
      'La corrección de saldo ya no existe en el dispositivo.',
    );
  });

  test('a correction made during an open visit waits for it, then travels '
      'linked to it', () async {
    await correct(BalanceTarget.debt, 900, visitId: 's-1');

    await engine.push();

    expect(server.pushBodies, isEmpty);
    expect((await queued('corr-1')).status, 'pending');

    await DriftVisitRepository(db).recordVisit(
      Visit(
        visitId: 'v-1',
        routeStopId: 's-1',
        customerId: 'c-1',
        visitType: VisitType.sale,
        arrivedAt: now,
      ),
    );
    await engine.push();

    expect(sent('balance_corrections').single['visit_uuid'], 'v-1');
    expect((await queued('corr-1')).status, 'sent');
  });

  test(
    'a correction and a later payment travel together, after the payments; '
    'the balance is the server one plus what is pending (ADR 0003)',
    () async {
      await db
          .into(db.syncStateTable)
          .insert(
            SyncStateTableCompanion.insert(
              key: SyncService.pullCursorKey,
              value: '2026-11-17T12:00:00+00:00',
            ),
          );
      await correct(BalanceTarget.debt, 800);
      await payments.recordPayment(
        Payment(
          id: 'pay-1',
          customerId: 'c-1',
          amount: 100,
          type: PaymentType.cash,
          createdAt: now,
        ),
      );
      expect(await balance(), 700);
      Json serverBalance(String value) => {
        'id': 500,
        'customer_id': 10,
        'current_balance': value,
        'enabled': true,
      };

      // Before pushing, the server still holds 1000: both stay on top.
      server.pullRows = {
        'customer_balances': [serverBalance('1000.00')],
      };
      await sync.pull();
      expect(await balance(), 700);

      await engine.push();

      final keys = server.pushBodies.single.keys.toList();
      expect(keys, ['payments', 'balance_corrections']);
      expect(sent('balance_corrections').single['seen_balance'], 1000.0);
      expect(await queue.countPending(), 0);

      // The server applied both: -200 and -100.
      server.pullRows = {
        'customer_balances': [serverBalance('700.00')],
      };
      await sync.pull();
      expect(await balance(), 700);
    },
  );
}
