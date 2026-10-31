import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/sales/data/repositories/sale.repository.dart';
import 'package:app/features/sales/domain/cancellation_reason.dart';
import 'package:app/features/sales/domain/same_day.dart';

class CancelSaleUseCase {
  CancelSaleUseCase({
    required SaleRepository saleRepo,
    required PaymentRepository paymentRepo,
    required InventoryRepository inventoryRepo,
    required TransactionRunner transaction,
    DateTime Function() now = DateTime.now,
  }) : _saleRepo = saleRepo,
       _paymentRepo = paymentRepo,
       _inventoryRepo = inventoryRepo,
       _transaction = transaction,
       _now = now;

  final SaleRepository _saleRepo;
  final PaymentRepository _paymentRepo;
  final InventoryRepository _inventoryRepo;
  final TransactionRunner _transaction;
  final DateTime Function() _now;

  /// Cancels a sale of today and the payments that settled it, in one unit
  /// of work, so the customer account returns to where it was before the
  /// sale, its stock goes back to the truck and the containers delivered and
  /// returned with it leave custody. Payments and container returns not
  /// linked to the sale (a debt payment, a return without a sale) are
  /// untouched.
  ///
  /// Cancelling a cancelled sale does nothing. Throws [ValidationFailure]
  /// for a sale of another day or a too long reason, and [NotFoundFailure]
  /// when the sale does not exist.
  Future<void> execute(String saleId, {String? reason}) async {
    final note = cancellationReason(reason);
    final now = _now();
    await _transaction(() async {
      final sale = await _saleRepo.findSale(saleId);
      if (sale == null) throw const NotFoundFailure('sale');
      if (sale.isCancelled) return;
      if (!isSameDay(sale.date, now)) {
        throw const ValidationFailure(
          'Solo se pueden anular las ventas de hoy.',
        );
      }

      await _saleRepo.cancelSale(sale, at: now, reason: note);
      await _inventoryRepo.reverseSaleMovements(saleId, at: now);
      for (final payment in await _paymentRepo.getSalePayments(saleId)) {
        if (payment.isCancelled) continue;
        await _paymentRepo.cancelPayment(payment, at: now, reason: note);
      }
    });
  }

  /// Applies a cancellation the server already holds (the office or a
  /// previous push cancelled [saleId] at [at]) with the same effects on the
  /// sale as [execute], whatever its day, and queues nothing. Its payments
  /// are left alone: the server does not cancel them with the sale and
  /// reports each one it cancels on its own.
  ///
  /// Returns false, changing nothing, when the sale is not on the device or
  /// is already cancelled.
  Future<bool> applyServerCancellation(
    String saleId, {
    required DateTime at,
    String? reason,
  }) => _transaction(() async {
    final sale = await _saleRepo.findSale(saleId);
    if (sale == null || sale.isCancelled) return false;
    await _saleRepo.cancelSale(sale, at: at, reason: reason, queue: false);
    await _inventoryRepo.reverseSaleMovements(sale.id, at: at);
    return true;
  });
}
