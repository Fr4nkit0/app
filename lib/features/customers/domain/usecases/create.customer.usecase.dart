import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';

class CreateCustomerUseCase {
  final CustomerRepository _customerRepository;
  final TransactionRunner _transaction;

  CreateCustomerUseCase({
    required CustomerRepository customerRepository,
    required TransactionRunner transaction,
  }) : _customerRepository = customerRepository,
       _transaction = transaction;

  /// Stores [customer] with its addresses, preferences and pending change in
  /// one unit of work. Throws [ValidationFailure] without a name, an address
  /// or a preference.
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

    await _transaction(() => _customerRepository.saveCustomer(customer));
  }
}
