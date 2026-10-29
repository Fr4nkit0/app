import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/inventory/domain/usecases/register_container_return.usecase.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';

final registerContainerReturnUseCaseProvider =
    Provider<RegisterContainerReturnUseCase>(
      (ref) => RegisterContainerReturnUseCase(
        inventoryRepo: ref.watch(inventoryRepositoryProvider),
        transaction: ref.watch(transactionRunnerProvider),
      ),
    );
