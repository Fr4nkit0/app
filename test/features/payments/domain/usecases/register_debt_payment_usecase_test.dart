import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/models/payment_split.dart';
import 'package:app/features/payments/domain/usecases/register_debt_payment.usecase.dart';

void main() {
  late AppDatabase db;
  late DriftPaymentRepository repo;
  final at = DateTime(2026, 10, 28, 9, 30);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftPaymentRepository(db);
  });
  tearDown(() => db.close());

  RegisterDebtPaymentUseCase useCase({String Function()? newId}) {
    var next = 0;
    return RegisterDebtPaymentUseCase(
      paymentRepo: repo,
      transaction: driftTransactionRunner(db),
      now: () => at,
      newId: newId ?? () => 'pay-${next++}',
    );
  }

  Future<void> expectNothingRecorded() async {
    expect(await db.select(db.paymentTable).get(), isEmpty);
    expect(await db.select(db.customerAccountEntryTable).get(), isEmpty);
    expect(await db.select(db.customerBalanceTable).get(), isEmpty);
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
  }

  test(
    'a cash payment records the payment, lowers the balance and queues it',
    () async {
      await useCase().execute(
        customerId: 'cust-1',
        split: const PaymentSplit(cash: 400),
        visitId: 'v1',
      );

      final payment = await db.select(db.paymentTable).getSingle();
      expect(payment.paymentId, 'pay-0');
      expect(payment.customerId, 'cust-1');
      expect(payment.amount, 400);
      expect(payment.paymentMethod, PaymentType.cash.dbValue);
      expect(payment.createdAt, at);
      expect(payment.visitId, 'v1');
      expect(await repo.watchCustomerBalance('cust-1').first, -400);
      expect(await db.select(db.pendingChangeTable).get(), hasLength(1));
    },
  );

  test(
    'a mixed payment records cash first and the transfer 10ms after it',
    () async {
      await useCase().execute(
        customerId: 'cust-1',
        split: const PaymentSplit(cash: 600, transfer: 400),
      );

      // The table keeps whole seconds; the queued payloads keep the offset.
      final queued = [
        for (final change in await db.select(db.pendingChangeTable).get())
          jsonDecode(change.payload!) as Map<String, dynamic>,
      ];
      expect(queued.map((p) => p['paymentMethod']), [
        PaymentType.cash.dbValue,
        PaymentType.transfer.dbValue,
      ]);
      expect(queued.map((p) => p['amount']), [600, 400]);
      expect(queued.map((p) => p['createdAt']), [
        at.toIso8601String(),
        at.add(PaymentSplit.transferAfterCash).toIso8601String(),
      ]);
      expect(await repo.watchCustomerBalance('cust-1').first, -1000);
    },
  );

  test(
    'an empty split throws a ValidationFailure and records nothing',
    () async {
      await expectLater(
        useCase().execute(customerId: 'cust-1', split: PaymentSplit.none),
        throwsA(isA<ValidationFailure>()),
      );
      await expectNothingRecorded();
    },
  );

  test(
    'a negative part throws a ValidationFailure and records nothing',
    () async {
      await expectLater(
        useCase().execute(
          customerId: 'cust-1',
          split: const PaymentSplit(cash: 500, transfer: -50),
        ),
        throwsA(isA<ValidationFailure>()),
      );
      await expectNothingRecorded();
    },
  );

  test(
    'a failing second write leaves no rows and no pending changes',
    () async {
      // Both payments get the same id, so the transfer insert fails after
      // the cash payment, its account entry and its pending change exist.
      await expectLater(
        useCase(newId: () => 'same-id').execute(
          customerId: 'cust-1',
          split: const PaymentSplit(cash: 600, transfer: 400),
        ),
        throwsA(isA<StorageFailure>()),
      );
      await expectNothingRecorded();
    },
  );
}
