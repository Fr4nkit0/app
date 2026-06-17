import 'package:app/core/utils/resource.dart';
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
  })  : _saleRepo = saleRepo,
        _paymentRepo = paymentRepo,
        _inventoryRepo = inventoryRepo;

  final SaleRepository _saleRepo;
  final PaymentRepository _paymentRepo;
  final InventoryRepository _inventoryRepo;

  Future<Resource<void>> execute(
    Sale sale, {
    Payment? payment,
    ContainerMovement? containerMovement,
  }) async {
    if (sale.items.isEmpty) {
      return Resource.error(
          Exception('Sale must contain at least one item'));
    }
    try {
      final saleResult = await _saleRepo.saveSale(sale);
      if (saleResult is Error) return saleResult;

      if (payment != null) {
        await _paymentRepo.recordPayment(payment);
      }
      if (containerMovement != null) {
        await _inventoryRepo.recordContainerMovement(containerMovement);
      }

      return const Resource.success(null);
    } on Exception catch (e) {
      return Resource.error(e);
    }
  }
}
