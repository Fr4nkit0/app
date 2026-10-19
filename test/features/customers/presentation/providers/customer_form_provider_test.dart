import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/presentation/providers/customer_form_state.dart';
import 'package:app/features/customers/presentation/providers/customer_form_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';

class FakeCustomerRepository implements CustomerRepository {
  Customer? lastSavedCustomer;

  @override
  Future<Resource<void>> saveCustomer(Customer customer) async {
    lastSavedCustomer = customer;
    return const Resource.success(null);
  }

  @override
  Future<Resource<void>> updateCustomer(Customer customer) => throw UnimplementedError();
  @override
  Future<Resource<void>> deleteCustomer(String customerId) => throw UnimplementedError();
  @override
  Future<Resource<Customer?>> getCustomerById(String id) => throw UnimplementedError();
  @override
  Future<List<Customer>> getCustomersPage({required int page, required int pageSize}) => throw UnimplementedError();
  @override
  Future<List<Customer>> searchCustomers({required String query, required int page, required int pageSize}) => throw UnimplementedError();
  @override
  Stream<int> watchCustomerCount() => throw UnimplementedError();
  @override
  Stream<List<Customer>> watchAllCustomers() => throw UnimplementedError();
  @override
  Future<Resource<void>> updateAddressCoordinates(String addressId, double latitude, double longitude) => throw UnimplementedError();
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
    });
  });
}
