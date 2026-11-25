import 'package:uuid/uuid.dart';

import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';

String _uuidV4() => const Uuid().v4();

/// Containers a customer hands back without a sale, and skeletons the
/// driver lends without one.
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

  /// Records one movement per container code with a returned quantity in
  /// [returns] or a delivered one in [deliveries] above zero, all of them or
  /// none; all zeros record nothing.
  Future<void> execute({
    required String customerId,
    required Map<String, int> returns,
    Map<String, int> deliveries = const {},
    String? visitId,
    String? routeId,
  }) async {
    int positive(int? quantity) => (quantity ?? 0) > 0 ? quantity! : 0;
    final codes = [
      for (final code in {...returns.keys, ...deliveries.keys})
        if (positive(returns[code]) > 0 || positive(deliveries[code]) > 0) code,
    ];
    if (codes.isEmpty) return;

    final at = _now();
    await _transaction(() async {
      for (final code in codes) {
        await _inventoryRepo.recordContainerMovement(
          ContainerMovement(
            id: _newId(),
            customerId: customerId,
            containerType: code,
            deliveredQuantity: positive(deliveries[code]),
            returnedQuantity: positive(returns[code]),
            createdAt: at,
            visitId: visitId,
            routeId: routeId,
          ),
        );
      }
    });
  }
}
