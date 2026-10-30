import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/drift.customer_agreement.repository.dart';
import 'package:app/features/customers/domain/usecases/add_address.usecase.dart';
import 'package:app/features/customers/domain/usecases/add_preference.usecase.dart';
import 'package:app/features/customers/domain/usecases/create.customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/create_customer_agreement.usecase.dart';
import 'package:app/features/customers/domain/usecases/disable_address.usecase.dart';
import 'package:app/features/customers/domain/usecases/disable_customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/disable_preference.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit.customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit_address.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit_preference.usecase.dart';
import 'package:app/features/customers/domain/usecases/set_primary_address.usecase.dart';
import 'package:app/features/customers/presentation/providers/customer_addresses_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_preferences_provider.dart';
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

final addAddressUseCaseProvider = Provider<AddAddressUseCase>(
  (ref) => AddAddressUseCase(
    addressRepo: ref.watch(customerAddressRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);

final editAddressUseCaseProvider = Provider<EditAddressUseCase>(
  (ref) => EditAddressUseCase(
    addressRepo: ref.watch(customerAddressRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);

final disableAddressUseCaseProvider = Provider<DisableAddressUseCase>(
  (ref) => DisableAddressUseCase(
    addressRepo: ref.watch(customerAddressRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);

final setPrimaryAddressUseCaseProvider = Provider<SetPrimaryAddressUseCase>(
  (ref) => SetPrimaryAddressUseCase(
    addressRepo: ref.watch(customerAddressRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);

final addPreferenceUseCaseProvider = Provider<AddPreferenceUseCase>(
  (ref) => AddPreferenceUseCase(
    preferenceRepo: ref.watch(customerPreferenceRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);

final editPreferenceUseCaseProvider = Provider<EditPreferenceUseCase>(
  (ref) => EditPreferenceUseCase(
    preferenceRepo: ref.watch(customerPreferenceRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);

final disablePreferenceUseCaseProvider = Provider<DisablePreferenceUseCase>(
  (ref) => DisablePreferenceUseCase(
    preferenceRepo: ref.watch(customerPreferenceRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);
