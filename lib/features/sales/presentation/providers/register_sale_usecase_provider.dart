import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';

final registerSaleUseCaseProvider = Provider<RegisterSaleUseCase>(
  (ref) => RegisterSaleUseCase(
    saleRepo: ref.watch(saleRepositoryProvider),
    paymentRepo: ref.watch(paymentRepositoryProvider),
    inventoryRepo: ref.watch(inventoryRepositoryProvider),
    db: ref.watch(databaseProvider),
  ),
);
