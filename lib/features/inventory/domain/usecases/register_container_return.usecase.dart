import 'package:uuid/uuid.dart';

import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';

String _uuidV4() => const Uuid().v4();

/// Containers a customer hands back without a sale.
class RegisterContainerReturnUseCase {
  const RegisterContainerReturnUseCase({
    required InventoryRepository inventoryRepo,
    required TransactionRunner transaction,
    DateTime Function() now = DateTime.now,
    String Function() newId = _uuidV4,
  }) : _inventoryRepo = inventoryRepo,
       _transaction = transaction,
       _now = now,
       _newId = newId;

  final InventoryRepository _inventoryRepo;
  final TransactionRunner _transaction;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Records one movement per container code in [returns] with a returned
  /// quantity above zero, all of them or none; all zeros record nothing.
  Future<void> execute({
    required String customerId,
    required Map<String, int> returns,
    String? visitId,
    String? routeId,
  }) async {
    final returned = {
      for (final entry in returns.entries)
        if (entry.value > 0) entry.key: entry.value,
    };
    if (returned.isEmpty) return;

    final at = _now();
    await _transaction(() async {
      for (final entry in returned.entries) {
        await _inventoryRepo.recordContainerMovement(
          ContainerMovement(
            id: _newId(),
            customerId: customerId,
            containerType: entry.key,
            deliveredQuantity: 0,
            returnedQuantity: entry.value,
            createdAt: at,
            visitId: visitId,
            routeId: routeId,
          ),
        );
      }
    });
  }
}
