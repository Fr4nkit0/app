import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/payments/data/repositories/customer_account.dart';
import 'package:app/features/payments/domain/models/customer_account_entry.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/sales/data/database/record_status.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

const _uuid = Uuid();

abstract class PaymentRepository {
  /// Writes the payments, their account entries, the customer balances and
  /// their pending changes; run it inside the use case's unit of work.
  Future<void> recordPayment(Payment payment);
  Future<void> recordPayments(List<Payment> payments);
  Stream<double> watchCustomerBalance(String customerId);
  Future<List<Payment>> getVisitPayments(String visitId);
  Stream<List<Payment>> watchVisitPayments(String visitId);
  Future<List<CustomerAccountEntry>> getCustomerLedger(String customerId);

  /// The payment [paymentId], cancelled or not; null when it does not exist.
  Future<Payment?> findPayment(String paymentId);

  /// The payments that settled the sale [saleId].
  Future<List<Payment>> getSalePayments(String saleId);

  /// Marks [payment] cancelled at [at], books its adjustment, puts it back
  /// on the customer balance and, unless [queue] is false (the server
  /// already holds the cancellation), queues the cancellation; run it inside
  /// the use case's unit of work.
  Future<void> cancelPayment(
    Payment payment, {
    required DateTime at,
    String? reason,
    bool queue = true,
  });
}

class DriftPaymentRepository implements PaymentRepository {
  DriftPaymentRepository(AppDatabase db)
    : _db = db,
      _queue = DriftPendingChangeRepository(db),
      _account = CustomerAccount(db);

  final AppDatabase _db;
  final PendingChangeRepository _queue;
  final CustomerAccount _account;

  @override
  Future<void> recordPayment(Payment payment) async {
    await recordPayments([payment]);
  }

  @override
  Future<void> recordPayments(List<Payment> payments) async {
    if (payments.isEmpty) return;

    final paymentsByCustomer = <String, List<Payment>>{};
    for (final p in payments) {
      paymentsByCustomer.putIfAbsent(p.customerId, () => []).add(p);
    }

    for (final entry in paymentsByCustomer.entries) {
      final customerId = entry.key;
      final customerPayments = entry.value;

      double totalAmount = 0.0;
      String? lastEntryId;

      for (final payment in customerPayments) {
        await _db
            .into(_db.paymentTable)
            .insert(
              PaymentTableCompanion.insert(
                paymentId: Value(payment.id),
                customerId: payment.customerId,
                amount: payment.amount,
                paymentMethod: payment.type.dbValue,
                createdAt: Value(payment.createdAt),
                visitId: Value(payment.visitId),
                saleId: Value(payment.saleId),
                notes: Value(payment.notes),
              ),
            );

        final entryId = _uuid.v4();
        lastEntryId = entryId;
        totalAmount += payment.amount;

        await _db
            .into(_db.customerAccountEntryTable)
            .insert(
              CustomerAccountEntryTableCompanion.insert(
                customerAccountEntryId: Value(entryId),
                customerId: payment.customerId,
                paymentId: Value(payment.id),
                entryType: 'PAYMENT',
                amount: payment.amount,
                direction: -1,
                // createdAt mirrors the payment timestamp for deterministic ordering
                createdAt: Value(payment.createdAt),
                description: const Value('Payment recorded'),
              ),
            );

        await _queue.enqueue(
          entity: PendingEntity.payment,
          entityId: payment.id,
          action: PendingAction.insert,
          payload: {
            'paymentId': payment.id,
            'customerId': payment.customerId,
            'amount': payment.amount,
            'paymentMethod': payment.type.dbValue,
            'visitId': payment.visitId,
            'saleId': payment.saleId,
            'notes': payment.notes,
            'createdAt': payment.createdAt.toIso8601String(),
          },
        );
      }

      await _account.post(customerId, -totalAmount, lastEntryId: lastEntryId);
    }
  }

  @override
  Stream<double> watchCustomerBalance(String customerId) {
    return _account.watchBalance(customerId);
  }

  @override
  Future<List<Payment>> getVisitPayments(String visitId) async {
    final rows = await (_db.select(
      _db.paymentTable,
    )..where((t) => t.visitId.equals(visitId))).get();
    return rows.map(_rowToPayment).toList();
  }

  @override
  Stream<List<Payment>> watchVisitPayments(String visitId) {
    return (_db.select(_db.paymentTable)
          ..where((t) => t.visitId.equals(visitId)))
        .watch()
        .map((rows) => rows.map(_rowToPayment).toList());
  }

  @override
  Future<List<CustomerAccountEntry>> getCustomerLedger(
    String customerId,
  ) async {
    final rows =
        await (_db.select(_db.customerAccountEntryTable)
              ..where((t) => t.customerId.equals(customerId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    return rows.map(_rowToEntry).toList();
  }

  @override
  Future<Payment?> findPayment(String paymentId) async {
    final row = await (_db.select(
      _db.paymentTable,
    )..where((t) => t.paymentId.equals(paymentId))).getSingleOrNull();
    return row == null ? null : _rowToPayment(row);
  }

  @override
  Future<List<Payment>> getSalePayments(String saleId) async {
    final rows = await (_db.select(
      _db.paymentTable,
    )..where((t) => t.saleId.equals(saleId))).get();
    return rows.map(_rowToPayment).toList();
  }

  @override
  Future<void> cancelPayment(
    Payment payment, {
    required DateTime at,
    String? reason,
    bool queue = true,
  }) async {
    await (_db.update(
      _db.paymentTable,
    )..where((t) => t.paymentId.equals(payment.id))).write(
      PaymentTableCompanion(
        status: const Value(RecordStatus.cancelled),
        cancelledAt: Value(at),
        cancellationReason: Value(reason),
        lastModifiedDate: Value(at),
      ),
    );

    // Like the server: an adjustment puts the amount back on the account.
    final entryId = _uuid.v4();
    await _db
        .into(_db.customerAccountEntryTable)
        .insert(
          CustomerAccountEntryTableCompanion.insert(
            customerAccountEntryId: Value(entryId),
            customerId: payment.customerId,
            paymentId: Value(payment.id),
            entryType: adjustmentEntry,
            amount: payment.amount,
            direction: 1,
            createdAt: Value(at),
            description: const Value('Payment cancelled'),
          ),
        );
    await _account.post(
      payment.customerId,
      payment.amount,
      lastEntryId: entryId,
    );

    if (!queue) return;
    await _queue.enqueue(
      entity: PendingEntity.paymentCancellation,
      entityId: payment.id,
      action: PendingAction.insert,
      payload: {
        'paymentId': payment.id,
        'cancelledAt': at.toIso8601String(),
        'reason': reason,
      },
    );
  }

  /// Takes back a cancellation the server refused: the payment counts
  /// again in the balance. Nothing is queued.
  Future<void> undoCancellation(String paymentId) async {
    final payment = await (_db.select(
      _db.paymentTable,
    )..where((t) => t.paymentId.equals(paymentId))).getSingleOrNull();
    if (payment == null || payment.status != RecordStatus.cancelled) return;
    await (_db.update(
      _db.paymentTable,
    )..where((t) => t.paymentId.equals(paymentId))).write(
      PaymentTableCompanion(
        status: const Value(RecordStatus.confirmed),
        cancelledAt: const Value(null),
        cancellationReason: const Value(null),
        lastModifiedDate: Value(DateTime.now()),
      ),
    );
    await (_db.delete(_db.customerAccountEntryTable)..where(
          (t) =>
              t.paymentId.equals(paymentId) &
              t.entryType.equals(adjustmentEntry),
        ))
        .go();
    await _account.post(payment.customerId, -payment.amount);
  }

  static const adjustmentEntry = 'ADJUSTMENT';

  Payment _rowToPayment(PaymentTableData row) => Payment(
    id: row.paymentId,
    customerId: row.customerId,
    amount: row.amount,
    type: PaymentType.fromDb(row.paymentMethod),
    createdAt: row.createdAt,
    visitId: row.visitId,
    saleId: row.saleId,
    notes: row.notes,
    isCancelled: row.status == RecordStatus.cancelled,
  );

  CustomerAccountEntry _rowToEntry(CustomerAccountEntryTableData row) =>
      CustomerAccountEntry(
        id: row.customerAccountEntryId,
        customerId: row.customerId,
        paymentId: row.paymentId,
        saleId: row.saleId,
        entryType: row.entryType,
        amount: row.amount,
        direction: row.direction,
        description: row.description,
        createdAt: row.createdAt,
      );
}
