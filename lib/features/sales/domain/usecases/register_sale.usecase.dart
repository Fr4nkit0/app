import 'package:uuid/uuid.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/sales/data/repositories/sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';

class RegisterSaleUseCase {
  const RegisterSaleUseCase({
    required SaleRepository saleRepo,
    required PaymentRepository paymentRepo,
    required InventoryRepository inventoryRepo,
    required AppDatabase db,
  }) : _saleRepo = saleRepo,
       _paymentRepo = paymentRepo,
       _inventoryRepo = inventoryRepo,
       _db = db;

  final SaleRepository _saleRepo;
  final PaymentRepository _paymentRepo;
  final InventoryRepository _inventoryRepo;
  final AppDatabase _db;

  Future<Resource<void>> execute(
    Sale sale, {
    Payment? payment,
    List<ContainerMovement>? containerMovements,
  }) async {
    if (sale.items.isEmpty) {
      return Resource.error(Exception('Sale must contain at least one item'));
    }
    try {
      await _db.transaction(() async {
        final saleResult = await _saleRepo.saveSale(sale);
        if (saleResult is Error) {
          throw saleResult.error;
        }

        final payments = [?payment, ...settlingPayments(sale)];
        if (payments.isNotEmpty) {
          await _paymentRepo.recordPayments(payments);
        }
        if (containerMovements != null) {
          for (final movement in containerMovements) {
            await _inventoryRepo.recordContainerMovement(movement);
          }
        }
      });

      return const Resource.success(null);
    } on Exception catch (e) {
      return Resource.error(e);
    }
  }

  /// The payments that settle [sale] on the spot, linked to it: the server
  /// books every sale on the customer's account, so a sale not sold on
  /// credit needs its payments to leave the balance where it was.
  static List<Payment> settlingPayments(Sale sale) {
    Payment part(int index, PaymentType type, double amount) => Payment(
      id: const Uuid().v5(Namespace.url.value, 'sale-payment/${sale.id}/$index'),
      customerId: sale.customer.id,
      amount: amount,
      type: type,
      createdAt: sale.date,
      visitId: sale.visitId,
      saleId: sale.id,
    );

    return switch (sale.paymentMethod) {
      PaymentMethod.cash => [part(0, PaymentType.cash, sale.total)],
      PaymentMethod.transfer => [part(0, PaymentType.transfer, sale.total)],
      PaymentMethod.mixed => [
        if ((sale.cashAmount ?? 0) > 0)
          part(0, PaymentType.cash, sale.cashAmount!),
        if ((sale.transferAmount ?? 0) > 0)
          part(1, PaymentType.transfer, sale.transferAmount!),
      ],
      PaymentMethod.credit || PaymentMethod.route => const [],
    };
  }
}
