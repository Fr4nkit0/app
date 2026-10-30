import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';

class DisableCustomerUseCase {
  final CustomerRepository _customerRepository;
  final TransactionRunner _transaction;

  DisableCustomerUseCase({
    required CustomerRepository customerRepository,
    required TransactionRunner transaction,
  }) : _customerRepository = customerRepository,
       _transaction = transaction;

  /// Disables the customer and queues it in one unit of work; the push sends
  /// `enabled: false` with its `modified_at`. Throws [NotFoundFailure] when
  /// the customer does not exist.
  Future<void> execute(String customerId) =>
      _transaction(() => _customerRepository.disableCustomer(customerId));
}
