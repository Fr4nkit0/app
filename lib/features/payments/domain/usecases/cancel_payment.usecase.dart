import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/sales/domain/cancellation_reason.dart';
import 'package:app/features/sales/domain/same_day.dart';

class CancelPaymentUseCase {
  CancelPaymentUseCase({
    required PaymentRepository paymentRepo,
    required TransactionRunner transaction,
    DateTime Function() now = DateTime.now,
  }) : _paymentRepo = paymentRepo,
       _transaction = transaction,
       _now = now;

  final PaymentRepository _paymentRepo;
  final TransactionRunner _transaction;
  final DateTime Function() _now;

  /// Cancels a payment of today that did not settle a sale (a debt
  /// payment), in one unit of work: its amount goes back on the customer
  /// account. A sale's payments are cancelled with the sale.
  ///
  /// Cancelling a cancelled payment does nothing. Throws
  /// [ValidationFailure] when the payment cannot be cancelled and
  /// [NotFoundFailure] when it does not exist.
  Future<void> execute(String paymentId, {String? reason}) async {
    final note = cancellationReason(reason);
    final now = _now();
    await _transaction(() async {
      final payment = await _paymentRepo.findPayment(paymentId);
      if (payment == null) throw const NotFoundFailure('payment');
      if (payment.isCancelled) return;
      if (payment.saleId != null) {
        throw const ValidationFailure(
          'Este cobro se anula junto con su venta.',
        );
      }
      if (!isSameDay(payment.createdAt, now)) {
        throw const ValidationFailure(
          'Solo se pueden anular los cobros de hoy.',
        );
      }

      await _paymentRepo.cancelPayment(payment, at: now, reason: note);
    });
  }
}
