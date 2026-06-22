import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => DriftInventoryRepository(ref.watch(databaseProvider)),
);

final customerContainerBalancesProvider =
    StreamProvider.family<List<CustomerContainerBalance>, String>((
      ref,
      customerId,
    ) {
      final repo = ref.watch(inventoryRepositoryProvider);
      return repo.watchContainerBalances(customerId);
    });

final visitMovementsProvider =
    FutureProvider.family<List<ContainerMovement>, String>((
      ref,
      visitId,
    ) {
      final repo = ref.watch(inventoryRepositoryProvider);
      return repo.getVisitMovements(visitId);
    });
