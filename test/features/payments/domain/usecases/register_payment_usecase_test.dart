import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/usecases/register_payment.usecase.dart';

void main() {
  late AppDatabase db;
  late DriftPaymentRepository repo;
  late RegisterPaymentUseCase sut;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftPaymentRepository(db);
    sut = RegisterPaymentUseCase(paymentRepo: repo);
  });

  tearDown(() async {
    await db.close();
  });

  Payment makePayment({
    String? id,
    String customerId = 'mock-customer-1',
    double amount = 100.0,
    PaymentType type = PaymentType.cash,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? const Uuid().v4(),
      customerId: customerId,
      amount: amount,
      type: type,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Scenario F3a — success
  // ───────────────────────────────────────────────────────────────

  group('execute — success', () {
    test(
      'F3a: returns Resource.success(null) and inserts PaymentTable row',
      () async {
        final result = await sut.execute([
          makePayment(id: 'pay-f3a', amount: 100.0),
        ]);

        expect(result, isA<Success<void>>());

        final rows = await db.select(db.paymentTable).get();
        expect(rows.length, 1);
        expect(rows.first.paymentId, 'pay-f3a');
        expect(rows.first.amount, 100.0);
      },
    );

    test('F3a: CustomerBalanceTable is updated after payment', () async {
      await sut.execute([makePayment(id: 'pay-balance', amount: 200.0)]);

      final balances = await db.select(db.customerBalanceTable).get();
      // DriftPaymentRepository updates or inserts a customer_balance row.
      // Balance is reduced by payment amount (direction: -1).
      expect(balances.isNotEmpty, isTrue);
    });

    test('positive amount just above zero is accepted', () async {
      final result = await sut.execute([makePayment(amount: 0.01)]);
      expect(result, isA<Success<void>>());
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Scenario F3b — zero amount rejected
  // ───────────────────────────────────────────────────────────────

  group('execute — zero amount', () {
    test('F3b: returns Resource.error for amount == 0.0', () async {
      final result = await sut.execute([makePayment(amount: 0.0)]);

      expect(result, isA<Error<void>>());
    });

    test('F3b: no DB write when amount is zero', () async {
      await sut.execute([makePayment(amount: 0.0)]);

      final rows = await db.select(db.paymentTable).get();
      expect(rows, isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Scenario F3c — negative amount rejected
  // ───────────────────────────────────────────────────────────────

  group('execute — negative amount', () {
    test('F3c: returns Resource.error for amount == -50.0', () async {
      final result = await sut.execute([makePayment(amount: -50.0)]);

      expect(result, isA<Error<void>>());
    });

    test('F3c: no DB write when amount is negative', () async {
      await sut.execute([makePayment(amount: -1.0)]);

      final rows = await db.select(db.paymentTable).get();
      expect(rows, isEmpty);
    });
  });
}
