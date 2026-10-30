import 'package:uuid/uuid.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/sales/data/repositories/sale.repository.dart';
import 'package:app/features/sales/domain/models/sale.dart';

class RegisterSaleUseCase {
  const RegisterSaleUseCase({
    required SaleRepository saleRepo,
    required PaymentRepository paymentRepo,
    required InventoryRepository inventoryRepo,
    required TransactionRunner transaction,
  }) : _saleRepo = saleRepo,
       _paymentRepo = paymentRepo,
       _inventoryRepo = inventoryRepo,
       _transaction = transaction;

  final SaleRepository _saleRepo;
  final PaymentRepository _paymentRepo;
  final InventoryRepository _inventoryRepo;
  final TransactionRunner _transaction;

  /// The server rejects a sale whose total differs from its items by more
  /// than this; such a sale would stay stuck in the outbox.
  static const totalTolerance = 0.005;

  /// Records [sale], its settling payments and [containerMovements] (linked
  /// to the sale) in one unit of work. Throws [ValidationFailure] for a sale
  /// without items or whose total does not match its items.
  Future<void> execute(
    Sale sale, {
    Payment? payment,
    List<ContainerMovement>? containerMovements,
  }) async {
    if (sale.items.isEmpty) {
      throw const ValidationFailure('La venta no tiene productos.');
    }
    final itemsTotal = sale.items.fold<double>(0, (sum, i) => sum + i.subtotal);
    if ((sale.total - itemsTotal).abs() > totalTolerance) {
      throw const ValidationFailure(
        'El total de la venta no coincide con sus productos.',
      );
    }
    await _transaction(() async {
      await _saleRepo.saveSale(sale);

      final payments = [?payment, ...settlingPayments(sale)];
      if (payments.isNotEmpty) {
        await _paymentRepo.recordPayments(payments);
      }
      if (containerMovements != null) {
        for (final movement in containerMovements) {
          await _inventoryRepo.recordContainerMovement(
            movement.withSale(sale.id),
          );
        }
      }
    });
  }

  /// The payments that settle [sale] on the spot, linked to it: the server
  /// books every sale on the customer's account, so a sale not sold on
  /// credit needs its payments to leave the balance where it was.
  static List<Payment> settlingPayments(Sale sale) =>
      sale.settlement.toPayments(
        customerId: sale.customer.id,
        at: sale.date,
        idFor: (i) =>
            const Uuid().v5(Namespace.url.value, 'sale-payment/${sale.id}/$i'),
        visitId: sale.visitId,
        saleId: sale.id,
      );
}
