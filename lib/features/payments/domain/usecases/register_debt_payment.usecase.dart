import 'package:uuid/uuid.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment_split.dart';

String _uuidV4() => const Uuid().v4();

/// A customer pays part or all of their debt, outside of a sale.
class RegisterDebtPaymentUseCase {
  const RegisterDebtPaymentUseCase({
    required PaymentRepository paymentRepo,
    required TransactionRunner transaction,
    DateTime Function() now = DateTime.now,
    String Function() newId = _uuidV4,
  }) : _paymentRepo = paymentRepo,
       _transaction = transaction,
       _now = now,
       _newId = newId;

  final PaymentRepository _paymentRepo;
  final TransactionRunner _transaction;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Records the payments of [split], the customer account and their
  /// pending changes in one unit of work. Throws [ValidationFailure] when
  /// [split] pays nothing or has a negative part.
  Future<void> execute({
    required String customerId,
    required PaymentSplit split,
    String? visitId,
  }) async {
    if (split.cash < 0 || split.transfer < 0 || split.total <= 0) {
      throw const ValidationFailure('Ingresá un monto mayor a 0.');
    }
    final payments = split.toPayments(
      customerId: customerId,
      at: _now(),
      idFor: (_) => _newId(),
      visitId: visitId,
    );
    await _transaction(() => _paymentRepo.recordPayments(payments));
  }
}
