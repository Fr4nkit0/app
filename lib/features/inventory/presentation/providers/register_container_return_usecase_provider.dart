import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/inventory/domain/usecases/register_container_return.usecase.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';

final registerContainerReturnUseCaseProvider =
    Provider<RegisterContainerReturnUseCase>(
      (ref) => RegisterContainerReturnUseCase(
        inventoryRepo: ref.watch(inventoryRepositoryProvider),
        transaction: ref.watch(databaseProvider).transaction,
      ),
    );
