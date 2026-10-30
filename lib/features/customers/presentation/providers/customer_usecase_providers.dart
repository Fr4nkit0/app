import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/drift.customer_agreement.repository.dart';
import 'package:app/features/customers/domain/usecases/create.customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/create_customer_agreement.usecase.dart';
import 'package:app/features/customers/domain/usecases/disable_customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit.customer.usecase.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';

final createCustomerUseCaseProvider = Provider<CreateCustomerUseCase>(
  (ref) => CreateCustomerUseCase(
    customerRepository: ref.watch(customerRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);

final editCustomerUseCaseProvider = Provider<EditCustomerUseCase>(
  (ref) => EditCustomerUseCase(
    customerRepository: ref.watch(customerRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);

final disableCustomerUseCaseProvider = Provider<DisableCustomerUseCase>(
  (ref) => DisableCustomerUseCase(
    customerRepository: ref.watch(customerRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);

final createCustomerAgreementUseCaseProvider =
    Provider<CreateCustomerAgreementUseCase>(
      (ref) => CreateCustomerAgreementUseCase(
        agreementRepo: ref.watch(driftCustomerAgreementRepositoryProvider),
        transaction: ref.watch(transactionRunnerProvider),
      ),
    );
