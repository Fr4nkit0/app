import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/domain/models/customer_edit.dart';

class EditCustomerUseCase {
  final CustomerRepository _customerRepository;
  final TransactionRunner _transaction;

  EditCustomerUseCase({
    required CustomerRepository customerRepository,
    required TransactionRunner transaction,
  }) : _customerRepository = customerRepository,
       _transaction = transaction;

  /// Writes [edit] and queues it in one unit of work; the push sends it with
  /// its `modified_at` and the server keeps the latest write. Throws
  /// [ValidationFailure] without a name and [NotFoundFailure] when the
  /// customer does not exist.
  Future<void> execute(CustomerEdit edit) async {
    if (edit.name.trim().isEmpty) {
      throw const ValidationFailure('El nombre es requerido');
    }

    await _transaction(() => _customerRepository.editCustomer(edit));
  }
}
