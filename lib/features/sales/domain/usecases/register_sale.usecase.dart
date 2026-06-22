import 'package:app/core/services/database.helper.dart';
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

        if (payment != null) {
          await _paymentRepo.recordPayment(payment);
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
}
