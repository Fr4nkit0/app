import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/usecases/cancel_payment.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

void main() {
  late AppDatabase db;
  late DriftPaymentRepository payments;
  late PendingChangeRepository queue;
  late CancelPaymentUseCase sut;

  final now = DateTime(2026, 10, 29, 11);

  Future<void> pay({
    String id = 'pay-1',
    DateTime? at,
    String? saleId,
  }) => payments.recordPayment(
    Payment(
      id: id,
      customerId: 'c-1',
      amount: 500,
      type: PaymentType.cash,
      createdAt: at ?? DateTime(2026, 10, 29, 10),
      visitId: 's-1',
      saleId: saleId,
    ),
  );

  Future<double> balance() => payments.watchCustomerBalance('c-1').first;

  Future<PaymentTableData> row([String id = 'pay-1']) => (db.select(
    db.paymentTable,
  )..where((t) => t.paymentId.equals(id))).getSingle();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    payments = DriftPaymentRepository(db);
    queue = DriftPendingChangeRepository(db);
    sut = CancelPaymentUseCase(
      paymentRepo: payments,
      transaction: driftTransactionRunner(db),
      now: () => now,
    );
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
          ),
        );
    await db
        .into(db.customerBalanceTable)
        .insert(
          CustomerBalanceTableCompanion.insert(
            customerId: 'c-1',
            currentBalance: const drift.Value(1000),
          ),
        );
  });
  tearDown(() => db.close());

  test('cancels a debt payment of today: the debt comes back and one '
      'payment cancellation is queued', () async {
    await pay();
    expect(await balance(), 500);

    await sut.execute('pay-1', reason: 'Billete falso');

    final payment = await row();
    expect(payment.status, 'CANCELLED');
    expect(payment.cancelledAt, now);
    expect(payment.cancellationReason, 'Billete falso');
    expect(await balance(), 1000);
    final adjustment = (await db.select(
      db.customerAccountEntryTable,
    ).get()).singleWhere((e) => e.entryType == 'ADJUSTMENT');
    expect(adjustment.paymentId, 'pay-1');
    expect(adjustment.amount, 500);
    expect(adjustment.direction, 1);
    final cancellations = [
      for (final c in await queue.getPending())
        if (c.entity == PendingEntity.paymentCancellation) c.entityId,
    ];
    expect(cancellations, ['pay-1']);
    expect((await payments.findPayment('pay-1'))?.isCancelled, isTrue);
  });

  test('a payment that settled a sale is cancelled with its sale', () async {
    await pay(saleId: 'sale-1');

    await expectLater(
      sut.execute('pay-1'),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'Este cobro se anula junto con su venta.',
        ),
      ),
    );
    expect((await row()).status, 'CONFIRMED');
  });

  test('a payment of another day cannot be cancelled', () async {
    await pay(at: DateTime(2026, 10, 28, 18));
    final pending = await queue.countPending();

    await expectLater(
      sut.execute('pay-1'),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'Solo se pueden anular los cobros de hoy.',
        ),
      ),
    );
    expect((await row()).status, 'CONFIRMED');
    expect(await queue.countPending(), pending);
    expect(await balance(), 500);
  });

  test('cancelling twice books nothing the second time', () async {
    await pay();
    await sut.execute('pay-1');
    final pending = await queue.countPending();

    await sut.execute('pay-1');

    expect(await queue.countPending(), pending);
    expect(await balance(), 1000);
  });

  test('an unknown payment is a NotFoundFailure', () async {
    await expectLater(sut.execute('missing'), throwsA(isA<NotFoundFailure>()));
  });
}
