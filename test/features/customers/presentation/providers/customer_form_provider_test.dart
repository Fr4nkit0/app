import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/balance_corrections/data/repositories/balance_correction.repository.dart';
import 'package:app/features/balance_corrections/domain/models/balance_correction.dart';
import 'package:app/features/balance_corrections/presentation/providers/correct_balance_usecase_provider.dart';
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
  balanceCorrectionRepositoryProvider.overrideWithValue(
    FakeBalanceCorrectionRepository(),
  ),
];

/// Keeps the corrections it is asked to record.
class FakeBalanceCorrectionRepository implements BalanceCorrectionRepository {
  final recorded = <BalanceCorrection>[];

  @override
  Future<void> record(BalanceCorrection correction) async =>
      recorded.add(correction);

  @override
  Future<double> shownBalance(
    String customerId,
    BalanceTarget target, {
    String? containerType,
  }) async => 0;

  @override
  Future<void> takeBack(String correctionId) => throw UnimplementedError();
}

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
  Future<void> disableCustomer(String customerId) => throw UnimplementedError();
  @override
  Future<Customer?> getCustomerById(String id) => throw UnimplementedError();
  @override
  Future<List<Customer>> getCustomersPage({required int page, required int pageSize}) => throw UnimplementedError();
  @override
  Future<List<Customer>> searchCustomers({required String query, required int page, required int pageSize}) => throw UnimplementedError();
  @override
  Stream<int> watchCustomerCount() => throw UnimplementedError();
  @override
  Stream<void> watchChanges() => throw UnimplementedError();
  @override
  Stream<Customer?> watchCustomer(String id) => throw UnimplementedError();
}

void main() {
  group('CustomerFormState & CustomerForm Provider', () {
    test('initial state has empty neighborhood', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(customerFormProvider);
      expect(state.neighborhood, '');
    });

    test('isAddressValid requires the street but not the neighborhood', () {
      const state1 = CustomerFormState(street: '', neighborhood: '');
      expect(state1.isAddressValid, isFalse);

      const state2 = CustomerFormState(street: 'Belgrano 1200', neighborhood: '');
      expect(state2.isAddressValid, isTrue);

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

  group('opening balance', () {
    late FakeCustomerRepository customers;
    late FakeBalanceCorrectionRepository corrections;
    late ProviderContainer container;

    setUp(() {
      customers = FakeCustomerRepository();
      corrections = FakeBalanceCorrectionRepository();
      container = ProviderContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(customers),
          transactionRunnerProvider.overrideWithValue(_inline),
          balanceCorrectionRepositoryProvider.overrideWithValue(corrections),
        ],
      );
    });
    tearDown(() => container.dispose());

    CustomerForm onPreferences() =>
        container.read(customerFormProvider.notifier)
          ..updateName('Gaston')
          ..nextStep()
          ..updateStreet('San Martin 100')
          ..nextStep();

    test('the typed debt and containers are saved as opening corrections '
        'of the new customer', () async {
      final notifier = onPreferences()
        ..showOpeningBalance()
        ..updateOpeningDebt('1500,50')
        ..updateOpeningContainers('B20', '2')
        ..updateOpeningContainers('SODA', '0');

      await notifier.submit();

      final state = container.read(customerFormProvider);
      expect(state.isSuccess, isTrue);
      final id = customers.lastSavedCustomer!.id;
      expect(
        [
          for (final c in corrections.recorded)
            (c.customerId, c.target, c.containerType, c.counted, c.seenBalance),
        ],
        [
          (id, BalanceTarget.debt, null, 1500.5, 0.0),
          (id, BalanceTarget.containers, 'B20', 2.0, 0.0),
        ],
      );
      expect(
        corrections.recorded.map((c) => c.reason).toSet(),
        {'Saldo inicial al dar de alta'},
      );
    });

    test('left empty, the customer is saved without corrections', () async {
      await onPreferences().submit();

      expect(container.read(customerFormProvider).isSuccess, isTrue);
      expect(customers.lastSavedCustomer, isNotNull);
      expect(corrections.recorded, isEmpty);
    });

    test('dropping the section clears what was typed', () async {
      final notifier = onPreferences()
        ..showOpeningBalance()
        ..updateOpeningDebt('300')
        ..updateOpeningContainers('B20', '2')
        ..clearOpeningBalance();

      final state = container.read(customerFormProvider);
      expect(state.isOpeningBalanceShown, isFalse);
      expect(state.openingDebt, '');
      expect(state.openingContainers, isEmpty);

      await notifier.submit();
      expect(corrections.recorded, isEmpty);
    });

    for (final (name, type) in <(String, void Function(CustomerForm))>[
      ('a negative debt', (f) => f.updateOpeningDebt('-500')),
      ('a debt that is not an amount', (f) => f.updateOpeningDebt('12a')),
      (
        'negative containers',
        (f) => f.updateOpeningContainers('B20', '-1'),
      ),
      (
        'a fraction of a container',
        (f) => f.updateOpeningContainers('B20', '2,5'),
      ),
    ]) {
      test('$name blocks the save and stores nothing', () async {
        final notifier = onPreferences()..showOpeningBalance();
        type(notifier);

        final typed = container.read(customerFormProvider);
        expect(typed.isOpeningBalanceValid, isFalse);
        expect(typed.isCurrentStepValid, isFalse);

        await notifier.submit();

        final state = container.read(customerFormProvider);
        expect(state.isSuccess, isFalse);
        expect(state.errorMessage, isNotNull);
        expect(customers.lastSavedCustomer, isNull);
        expect(corrections.recorded, isEmpty);
      });
    }

    test('the field errors are in Spanish', () {
      onPreferences()
        ..showOpeningBalance()
        ..updateOpeningDebt('-500')
        ..updateOpeningContainers('B20', '2,5');

      final state = container.read(customerFormProvider);
      expect(
        state.openingDebtError,
        'Ingresá un monto mayor o igual a cero.',
      );
      expect(state.openingContainerErrors, {
        'B20': 'Ingresá un número entero mayor o igual a cero.',
      });
    });
  });
}
