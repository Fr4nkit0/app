import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/payments/domain/models/customer_account_entry.dart';
import 'package:app/features/payments/domain/models/payment.dart';

const _uuid = Uuid();

abstract class PaymentRepository {
  Future<void> recordPayment(Payment payment);
  Stream<double> watchCustomerBalance(String customerId);
  Future<List<Payment>> getVisitPayments(String visitId);
  Future<List<CustomerAccountEntry>> getCustomerLedger(String customerId);
}

class DriftPaymentRepository implements PaymentRepository {
  DriftPaymentRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> recordPayment(Payment payment) async {
    await _db.transaction(() async {
      await _db.into(_db.paymentTable).insert(
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
      await _db.into(_db.customerAccountEntryTable).insert(
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

      final existing = await (_db.select(_db.customerBalanceTable)
            ..where((t) => t.customerId.equals(payment.customerId)))
          .getSingleOrNull();

      final newBalance = (existing?.currentBalance ?? 0.0) - payment.amount;

      if (existing == null) {
        await _db.into(_db.customerBalanceTable).insert(
              CustomerBalanceTableCompanion.insert(
                customerId: payment.customerId,
                currentBalance: Value(newBalance),
                lastEntryId: Value(entryId),
              ),
            );
      } else {
        await (_db.update(_db.customerBalanceTable)
              ..where((t) => t.customerId.equals(payment.customerId)))
            .write(CustomerBalanceTableCompanion(
          currentBalance: Value(newBalance),
          lastEntryId: Value(entryId),
        ));
      }

      await _db.into(_db.auditLogTable).insert(
            AuditLogTableCompanion.insert(
              tableNameColumn: 'payments',
              recordId: payment.id,
              action: 'INSERT',
              payload: Value(jsonEncode({
                'paymentId': payment.id,
                'customerId': payment.customerId,
                'amount': payment.amount,
                'paymentMethod': payment.type.dbValue,
              })),
            ),
          );
    });
  }

  @override
  Stream<double> watchCustomerBalance(String customerId) {
    return (_db.select(_db.customerBalanceTable)
          ..where((t) => t.customerId.equals(customerId)))
        .watchSingleOrNull()
        .map((row) => row?.currentBalance ?? 0.0);
  }

  @override
  Future<List<Payment>> getVisitPayments(String visitId) async {
    final rows = await (_db.select(_db.paymentTable)
          ..where((t) => t.visitId.equals(visitId)))
        .get();
    return rows.map(_rowToPayment).toList();
  }

  @override
  Future<List<CustomerAccountEntry>> getCustomerLedger(String customerId) async {
    final rows = await (_db.select(_db.customerAccountEntryTable)
          ..where((t) => t.customerId.equals(customerId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_rowToEntry).toList();
  }

  Payment _rowToPayment(PaymentTableData row) => Payment(
        id: row.paymentId,
        customerId: row.customerId,
        amount: row.amount,
        type: PaymentType.fromDb(row.paymentMethod),
        createdAt: row.createdAt,
        visitId: row.visitId,
        saleId: row.saleId,
        notes: row.notes,
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
