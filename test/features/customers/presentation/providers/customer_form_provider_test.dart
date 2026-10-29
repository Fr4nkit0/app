import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer_edit.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/presentation/providers/customer_form_state.dart';
import 'package:app/features/customers/presentation/providers/customer_form_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';

/// Runs the unit of work inline; the fakes below have no database.
Future<T> _inline<T>(Future<T> Function() action) => action();

/// Overrides that let the customer form save without a database.
final List<Override> fakeCustomerSaving = [
  transactionRunnerProvider.overrideWithValue(_inline),
];

class FakeCustomerRepository implements CustomerRepository {
  FakeCustomerRepository({this.failure});

  final Object? failure;
  Customer? lastSavedCustomer;

  @override
  Future<void> saveCustomer(Customer customer) async {
    if (failure case final failure?) throw failure;
    lastSavedCustomer = customer;
  }

  @override
  Future<void> editCustomer(CustomerEdit edit) => throw UnimplementedError();
  @override
  Future<Customer?> getCustomerById(String id) => throw UnimplementedError();
  @override
  Future<List<Customer>> getCustomersPage({required int page, required int pageSize}) => throw UnimplementedError();
  @override
  Future<List<Customer>> searchCustomers({required String query, required int page, required int pageSize}) => throw UnimplementedError();
  @override
  Stream<int> watchCustomerCount() => throw UnimplementedError();
  @override
  Stream<List<Customer>> watchAllCustomers() => throw UnimplementedError();
}

void main() {
  group('CustomerFormState & CustomerForm Provider', () {
    test('initial state has empty neighborhood', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(customerFormProvider);
      expect(state.neighborhood, '');
    });

    test('isAddressValid requires both street and neighborhood', () {
      const state1 = CustomerFormState(street: '', neighborhood: '');
      expect(state1.isAddressValid, isFalse);

      const state2 = CustomerFormState(street: 'Belgrano 1200', neighborhood: '');
      expect(state2.isAddressValid, isFalse);

      const state3 = CustomerFormState(street: '', neighborhood: 'Centro');
      expect(state3.isAddressValid, isFalse);

      const state4 = CustomerFormState(street: 'Belgrano 1200', neighborhood: 'Centro');
      expect(state4.isAddressValid, isTrue);
    });

    test('updateNeighborhood updates state and clears error message', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(customerFormProvider.notifier);
      
      // Seed an error
      notifier.nextStep(); // will trigger error because fields are empty
      expect(container.read(customerFormProvider).errorMessage, isNotNull);

      notifier.updateNeighborhood('Grand Bourg');
      final state = container.read(customerFormProvider);
      expect(state.neighborhood, 'Grand Bourg');
      expect(state.errorMessage, isNull);
    });

    test('submit maps neighborhood to CustomerAddress on creation', () async {
      final fakeRepo = FakeCustomerRepository();
      final container = ProviderContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(fakeRepo),
          ...fakeCustomerSaving,
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(customerFormProvider.notifier);

      // Set valid state for submission (currentStep = 2)
      notifier.updateName('Gaston');
      notifier.nextStep(); // to step 1
      notifier.updateStreet('San Martin 100');
      notifier.updateNeighborhood('Centro');
      notifier.nextStep(); // to step 2

      // Verify fields are valid
      final stateBefore = container.read(customerFormProvider);
      expect(stateBefore.currentStep, 2);
      expect(stateBefore.isCurrentStepValid, isTrue);

      await notifier.submit();

      final stateAfter = container.read(customerFormProvider);
      expect(stateAfter.isSuccess, isTrue);
      expect(fakeRepo.lastSavedCustomer, isNotNull);
      expect(fakeRepo.lastSavedCustomer!.name, 'Gaston');
      expect(fakeRepo.lastSavedCustomer!.addresses.first.street, 'San Martin 100');
      expect(fakeRepo.lastSavedCustomer!.addresses.first.neighborhood, 'Centro');
      // The saved customer is handed back so the sale can select it right away.
      expect(stateAfter.createdCustomer?.id, fakeRepo.lastSavedCustomer!.id);
      expect(stateAfter.createdCustomer?.name, 'Gaston');
    });

    test('a failed save keeps the form and shows the fallback copy', () async {
      final container = ProviderContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(
            FakeCustomerRepository(
              failure: StorageFailure(Exception('disk full')),
            ),
          ),
          ...fakeCustomerSaving,
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(customerFormProvider.notifier)
        ..updateName('Gaston')
        ..nextStep()
        ..updateStreet('San Martin 100')
        ..updateNeighborhood('Centro')
        ..nextStep();

      await notifier.submit();

      final state = container.read(customerFormProvider);
      expect(state.isSuccess, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.errorMessage, 'No se guardó el cliente. Reintentá.');
    });
  });
}
