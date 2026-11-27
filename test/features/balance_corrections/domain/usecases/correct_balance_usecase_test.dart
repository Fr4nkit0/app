import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/balance_corrections/data/repositories/balance_correction.repository.dart';
import 'package:app/features/balance_corrections/domain/models/balance_correction.dart';
import 'package:app/features/balance_corrections/domain/usecases/correct_balance.usecase.dart';
import 'package:app/features/history/data/repositories/history.repository.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/inventory/data/repositories/custody.dart';
import 'package:app/features/payments/data/repositories/customer_account.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

void main() {
  late AppDatabase db;
  late CustomerAccount account;
  late Custody custody;
  final at = DateTime(2026, 11, 17, 10, 15);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    account = CustomerAccount(db);
    custody = Custody(db);
  });
  tearDown(() => db.close());

  CorrectBalanceUseCase useCase() => CorrectBalanceUseCase(
    repo: DriftBalanceCorrectionRepository(db),
    transaction: driftTransactionRunner(db),
    now: () => at,
    newId: () => 'corr-1',
  );

  Future<void> expectNothingRecorded() async {
    expect(await db.select(db.balanceCorrectionTable).get(), isEmpty);
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
  }

  group('debt', () {
    test(
      'records the counted debt, the balance seen, and moves the account to it',
      () async {
        await account.post('cust-1', 1500);

        await useCase().execute(
          customerId: 'cust-1',
          target: BalanceTarget.debt,
          counted: 1200,
          reason: '  Pagó en efectivo y no se registró  ',
        );

        final row = await db.select(db.balanceCorrectionTable).getSingle();
        expect(row.correctionId, 'corr-1');
        expect(row.customerId, 'cust-1');
        expect(row.target, 'debt');
        expect(row.containerType, isNull);
        expect(row.counted, 1200);
        expect(row.seenBalance, 1500);
        expect(row.reason, 'Pagó en efectivo y no se registró');
        expect(row.correctedAt, at);
        expect(await account.balanceOf('cust-1'), 1200);

        final change = await db.select(db.pendingChangeTable).getSingle();
        expect(change.entity, PendingEntity.balanceCorrection.wireName);
        expect(change.entityId, 'corr-1');
        expect(change.action, PendingAction.insert.wireName);
        expect(change.status, PendingStatus.pending.wireName);
        expect(jsonDecode(change.payload!), containsPair('counted', 1200));
      },
    );

    test('accepts a negative debt (credit) in whole pesos', () async {
      await useCase().execute(
        customerId: 'cust-1',
        target: BalanceTarget.debt,
        counted: -200,
        reason: 'Saldo a favor',
      );

      final row = await db.select(db.balanceCorrectionTable).getSingle();
      expect(row.counted, -200);
      expect(row.seenBalance, 0);
      expect(await account.balanceOf('cust-1'), -200);
    });

    test('records the balance seen exactly', () async {
      await account.post('cust-1', 1000);
      await account.post('cust-1', 1);
      await account.post('cust-1', 2);

      await useCase().execute(
        customerId: 'cust-1',
        target: BalanceTarget.debt,
        counted: 1000,
        reason: 'Recontado',
      );

      final row = await db.select(db.balanceCorrectionTable).getSingle();
      expect(row.seenBalance, 1003);
      expect(await account.balanceOf('cust-1'), 1000);
    });

    test('the next download keeps the pending difference (ADR 0003)', () async {
      await account.post('cust-1', 1500);
      await useCase().execute(
        customerId: 'cust-1',
        target: BalanceTarget.debt,
        counted: 1200,
        reason: 'Recontado',
      );

      await account.reconcile('cust-1', 1000);

      expect(await account.balanceOf('cust-1'), 700);
    });
  });

  group('containers', () {
    test(
      'records the counted custody of one type and moves it there',
      () async {
        await custody.post('cust-1', 'JUG', 3);
        await custody.post('cust-1', 'SIPHON', 2);

        await useCase().execute(
          customerId: 'cust-1',
          target: BalanceTarget.containers,
          containerType: 'JUG',
          counted: 5,
          reason: 'Conté 5 bidones',
        );

        final row = await db.select(db.balanceCorrectionTable).getSingle();
        expect(row.target, 'containers');
        expect(row.containerType, 'JUG');
        expect(row.counted, 5);
        expect(row.seenBalance, 3);
        final balances = {
          for (final b in await custody.watch('cust-1').first)
            b.containerType: b.quantity,
        };
        expect(balances, {'JUG': 5, 'SIPHON': 2});
      },
    );

    test('the next download keeps the pending difference (ADR 0003)', () async {
      await custody.post('cust-1', 'JUG', 3);
      await useCase().execute(
        customerId: 'cust-1',
        target: BalanceTarget.containers,
        containerType: 'JUG',
        counted: 1,
        reason: 'Devolvió 2 sin registrar',
      );

      await custody.reconcile('cust-1', 'JUG', 4);

      final jug = (await custody.watch('cust-1').first).single;
      expect(jug.quantity, 2);
    });

    for (final counted in [-1]) {
      test('rejects $counted containers and records nothing', () async {
        await expectLater(
          useCase().execute(
            customerId: 'cust-1',
            target: BalanceTarget.containers,
            containerType: 'JUG',
            counted: counted,
            reason: 'Conteo',
          ),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.message,
              'message',
              'Los envases contados deben ser un número entero mayor o igual a cero.',
            ),
          ),
        );
        await expectNothingRecorded();
      });
    }

    test('requires the container type', () async {
      await expectLater(
        useCase().execute(
          customerId: 'cust-1',
          target: BalanceTarget.containers,
          counted: 1,
          reason: 'Conteo',
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            'Elegí el tipo de envase a corregir.',
          ),
        ),
      );
      await expectNothingRecorded();
    });
  });

  group('reason', () {
    test('a reason shorter than 3 characters is rejected', () async {
      await expectLater(
        useCase().execute(
          customerId: 'cust-1',
          target: BalanceTarget.debt,
          counted: 0,
          reason: '  ok  ',
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            'Escribí el motivo de la corrección (al menos 3 caracteres).',
          ),
        ),
      );
      await expectNothingRecorded();
    });

    test('a reason longer than 500 characters is rejected', () async {
      await expectLater(
        useCase().execute(
          customerId: 'cust-1',
          target: BalanceTarget.debt,
          counted: 0,
          reason: 'x' * 501,
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            'El motivo no puede superar los 500 caracteres.',
          ),
        ),
      );
      await expectNothingRecorded();
    });
  });

  group('history', () {
    test('lists a debt correction with the balances in driver copy', () async {
      await account.post('cust-1', 1500);
      await useCase().execute(
        customerId: 'cust-1',
        target: BalanceTarget.debt,
        counted: -200,
        reason: 'Pagó de más',
      );

      final entry = (await DriftHistoryRepository(
        db,
      ).watchHistory().first).single;
      expect(entry.type, HistoryEntryType.customer);
      expect(entry.customerId, 'cust-1');
      expect(
        entry.description,
        r'Debe $1.500 → Saldo a favor: $200 · Pagó de más',
      );
      expect(entry.status, PendingStatus.pending);
    });

    test('lists a container correction with the counts', () async {
      await custody.post('cust-1', 'JUG', 3);
      await useCase().execute(
        customerId: 'cust-1',
        target: BalanceTarget.containers,
        containerType: 'JUG',
        counted: 5,
        reason: 'Conté 5',
      );

      final entry = (await DriftHistoryRepository(
        db,
      ).watchHistory().first).single;
      expect(entry.description, 'Envases JUG: 3 → 5 · Conté 5');
    });
  });
}
