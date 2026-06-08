import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';

void main() {
  late AppDatabase db;
  late DriftPaymentRepository sut;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftPaymentRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Payment makePayment({
    String id = 'pay-1',
    String customerId = 'mock-customer-1',
    double amount = 500.0,
    PaymentType type = PaymentType.cash,
    String? visitId,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id,
      customerId: customerId,
      amount: amount,
      type: type,
      createdAt: createdAt ?? DateTime.now(),
      visitId: visitId,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // recordPayment
  // ──────────────────────────────────────────────────────────────────────────

  group('recordPayment', () {
    test('inserts payment row with correct values', () async {
      await sut.recordPayment(makePayment(id: 'pay-1', amount: 500.0));

      final rows = await db.select(db.paymentTable).get();
      expect(rows.length, 1);
      expect(rows.first.paymentId, 'pay-1');
      expect(rows.first.amount, 500.0);
      expect(rows.first.paymentMethod, 'EFECTIVO');
      expect(rows.first.customerId, 'mock-customer-1');
    });

    test('payment method is mapped correctly for each PaymentType', () async {
      await sut.recordPayment(
          makePayment(id: 'p-cash', type: PaymentType.cash));
      await sut.recordPayment(
          makePayment(id: 'p-transfer', type: PaymentType.transfer));
      await sut.recordPayment(
          makePayment(id: 'p-credit', type: PaymentType.credit));

      final rows = await db.select(db.paymentTable).get();
      final methods = {for (final r in rows) r.paymentId: r.paymentMethod};

      expect(methods['p-cash'], 'EFECTIVO');
      expect(methods['p-transfer'], 'TRANSFERENCIA');
      expect(methods['p-credit'], 'CREDIT');
    });

    test('creates ledger entry with direction -1 for PAYMENT', () async {
      await sut.recordPayment(makePayment(amount: 300.0));

      final entries = await db.select(db.customerAccountEntryTable).get();
      expect(entries.length, 1);
      expect(entries.first.entryType, 'PAYMENT');
      expect(entries.first.direction, -1);
      expect(entries.first.amount, 300.0);
      expect(entries.first.customerId, 'mock-customer-1');
      expect(entries.first.paymentId, 'pay-1');
    });

    test('creates customer balance row on first payment', () async {
      await sut.recordPayment(makePayment(amount: 300.0));

      final rows = await db.select(db.customerBalanceTable).get();
      expect(rows.length, 1);
      expect(rows.first.customerId, 'mock-customer-1');
      expect(rows.first.currentBalance, -300.0);
    });

    test('decreases balance on subsequent payments for same customer', () async {
      await sut.recordPayment(makePayment(id: 'pay-1', amount: 200.0));
      await sut.recordPayment(makePayment(id: 'pay-2', amount: 150.0));

      final rows = await db.select(db.customerBalanceTable).get();
      expect(rows.length, 1);
      expect(rows.first.currentBalance, -350.0);
    });

    test('updates lastEntryId on customer balance after payment', () async {
      await sut.recordPayment(makePayment());

      final balanceRow = await db.select(db.customerBalanceTable).getSingle();
      expect(balanceRow.lastEntryId, isNotNull);

      final entryRow =
          await db.select(db.customerAccountEntryTable).getSingle();
      expect(balanceRow.lastEntryId, entryRow.customerAccountEntryId);
    });

    test('balance tracks independent customers separately', () async {
      await sut.recordPayment(
          makePayment(id: 'p1', customerId: 'mock-customer-1', amount: 100.0));
      await sut.recordPayment(
          makePayment(id: 'p2', customerId: 'mock-customer-2', amount: 250.0));

      final rows = await db.select(db.customerBalanceTable).get();
      expect(rows.length, 2);

      final c1 =
          rows.firstWhere((r) => r.customerId == 'mock-customer-1');
      final c2 =
          rows.firstWhere((r) => r.customerId == 'mock-customer-2');
      expect(c1.currentBalance, -100.0);
      expect(c2.currentBalance, -250.0);
    });

    test('logs audit entry with correct table, action and recordId', () async {
      await sut.recordPayment(makePayment(id: 'pay-audit'));

      final logs = await db.select(db.auditLogTable).get();
      expect(logs.length, 1);
      expect(logs.first.action, 'INSERT');
      expect(logs.first.tableNameColumn, 'payments');
      expect(logs.first.recordId, 'pay-audit');
      expect(logs.first.payload, isNotNull);
    });

    test('rolls back all writes when payment insert fails (duplicate PK)',
        () async {
      // Pre-insert so the second recordPayment triggers a unique constraint.
      await db.into(db.paymentTable).insert(
            PaymentTableCompanion.insert(
              paymentId: const drift.Value('pay-dupe'),
              customerId: 'mock-customer-1',
              amount: 100.0,
              paymentMethod: 'EFECTIVO',
            ),
          );

      await expectLater(
        sut.recordPayment(makePayment(id: 'pay-dupe', amount: 999.0)),
        throwsA(anything),
      );

      // Nothing from the failed transaction should have been committed.
      final ledger = await db.select(db.customerAccountEntryTable).get();
      expect(ledger, isEmpty);

      final balances = await db.select(db.customerBalanceTable).get();
      expect(balances, isEmpty);

      final logs = await db.select(db.auditLogTable).get();
      expect(logs, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // watchCustomerBalance
  // ──────────────────────────────────────────────────────────────────────────

  group('watchCustomerBalance', () {
    test('emits 0.0 when no balance row exists for the customer', () async {
      final balance =
          await sut.watchCustomerBalance('mock-customer-1').first;
      expect(balance, 0.0);
    });

    test('emits updated balance after a payment is recorded', () async {
      final emissions = <double>[];
      final sub =
          sut.watchCustomerBalance('mock-customer-1').listen(emissions.add);
      addTearDown(sub.cancel);

      await Future.delayed(const Duration(milliseconds: 30));

      await sut.recordPayment(makePayment(amount: 400.0));

      await Future.delayed(const Duration(milliseconds: 30));

      expect(emissions.first, 0.0);
      expect(emissions.last, -400.0);
    });

    test('emits correct balance after multiple payments', () async {
      await sut.recordPayment(makePayment(id: 'pay-1', amount: 100.0));
      await sut.recordPayment(makePayment(id: 'pay-2', amount: 200.0));

      final balance =
          await sut.watchCustomerBalance('mock-customer-1').first;
      expect(balance, -300.0);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // getVisitPayments
  // ──────────────────────────────────────────────────────────────────────────

  group('getVisitPayments', () {
    test('returns only payments for the given visitId', () async {
      await sut
          .recordPayment(makePayment(id: 'p-v1', visitId: 'visit-abc'));
      await sut
          .recordPayment(makePayment(id: 'p-v2', visitId: 'visit-xyz'));

      final results = await sut.getVisitPayments('visit-abc');
      expect(results.length, 1);
      expect(results.first.id, 'p-v1');
    });

    test('returns multiple payments for the same visit', () async {
      await sut
          .recordPayment(makePayment(id: 'p-a', visitId: 'visit-1'));
      await sut
          .recordPayment(makePayment(id: 'p-b', visitId: 'visit-1'));

      final results = await sut.getVisitPayments('visit-1');
      expect(results.length, 2);
    });

    test('returns empty list for an unknown visitId', () async {
      final results = await sut.getVisitPayments('visit-nonexistent');
      expect(results, isEmpty);
    });

    test('payment domain model is mapped correctly from DB row', () async {
      await sut.recordPayment(makePayment(
        id: 'p-map',
        amount: 750.0,
        type: PaymentType.transfer,
        visitId: 'visit-map',
      ));

      final results = await sut.getVisitPayments('visit-map');
      final p = results.first;
      expect(p.id, 'p-map');
      expect(p.customerId, 'mock-customer-1');
      expect(p.amount, 750.0);
      expect(p.type, PaymentType.transfer);
      expect(p.visitId, 'visit-map');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // getCustomerLedger
  // ──────────────────────────────────────────────────────────────────────────

  group('getCustomerLedger', () {
    test('returns empty list for unknown customer', () async {
      final entries = await sut.getCustomerLedger('unknown-customer');
      expect(entries, isEmpty);
    });

    test('returns all ledger entries for a customer', () async {
      await sut.recordPayment(makePayment(id: 'pay-1', amount: 100.0));
      await sut.recordPayment(makePayment(id: 'pay-2', amount: 200.0));

      final entries = await sut.getCustomerLedger('mock-customer-1');
      expect(entries.length, 2);
    });

    test('returns entries sorted by createdAt descending (most recent first)',
        () async {
      final earlier = DateTime(2024, 1, 1);
      final later = DateTime(2024, 1, 2);

      await sut.recordPayment(
          makePayment(id: 'pay-old', amount: 100.0, createdAt: earlier));
      await sut.recordPayment(
          makePayment(id: 'pay-new', amount: 200.0, createdAt: later));

      final entries = await sut.getCustomerLedger('mock-customer-1');
      expect(entries.first.paymentId, 'pay-new');
      expect(entries.last.paymentId, 'pay-old');
    });

    test('ledger entry fields are mapped correctly', () async {
      await sut.recordPayment(makePayment(amount: 750.0));

      final entries = await sut.getCustomerLedger('mock-customer-1');
      expect(entries.length, 1);

      final e = entries.first;
      expect(e.entryType, 'PAYMENT');
      expect(e.amount, 750.0);
      expect(e.direction, -1);
      expect(e.customerId, 'mock-customer-1');
      expect(e.paymentId, 'pay-1');
      expect(e.id, isNotNull);
    });

    test('does not return entries for a different customer', () async {
      await sut.recordPayment(
          makePayment(id: 'p1', customerId: 'mock-customer-1'));
      await sut.recordPayment(
          makePayment(id: 'p2', customerId: 'mock-customer-2'));

      final entries = await sut.getCustomerLedger('mock-customer-1');
      expect(entries.length, 1);
      expect(entries.first.customerId, 'mock-customer-1');
    });
  });
}
