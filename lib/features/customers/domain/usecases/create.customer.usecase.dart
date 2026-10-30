import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/customers/domain/usecases/add_preference.usecase.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';

class CreateCustomerUseCase {
  final CustomerRepository _customerRepository;
  final TransactionRunner _transaction;

  CreateCustomerUseCase({
    required CustomerRepository customerRepository,
    required TransactionRunner transaction,
  }) : _customerRepository = customerRepository,
       _transaction = transaction;

  /// Stores [customer] with its addresses, preferences and pending changes
  /// in one unit of work. Throws [ValidationFailure] without a name, an
  /// address or a preference, and for preferences the server would refuse:
  /// a window ending before it starts, or two on the same day and start.
  Future<void> execute(Customer customer) async {
    if (customer.name.isEmpty) {
      throw const ValidationFailure('El nombre es requerido');
    }
    if (customer.addresses.isEmpty) {
      throw const ValidationFailure('Debe existir al menos una dirección');
    }
    if (customer.preferences.isEmpty) {
      throw const ValidationFailure('Debe existir al menos una preferencia');
    }
    final windows = <PreferenceDetails>[];
    for (final p in customer.preferences) {
      final window = PreferenceDetails(
        dayOfWeek: p.dayOfWeek,
        start: p.timeWindowStart,
        end: p.timeWindowEnd,
      ).normalized()..validate();
      if (windows.any((w) => w.sameSlot(window.dayOfWeek, window.start))) {
        throw const ValidationFailure(AddPreferenceUseCase.slotTaken);
      }
      windows.add(window);
    }

    await _transaction(() => _customerRepository.saveCustomer(customer));
  }
}
