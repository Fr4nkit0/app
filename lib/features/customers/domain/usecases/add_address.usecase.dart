import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_address.repository.dart';
import 'package:app/features/customers/domain/models/address_details.dart';

/// The driver adds a delivery address to a customer.
class AddAddressUseCase {
  const AddAddressUseCase({
    required CustomerAddressRepository addressRepo,
    required TransactionRunner transaction,
  }) : _addressRepo = addressRepo,
       _transaction = transaction;

  final CustomerAddressRepository _addressRepo;
  final TransactionRunner _transaction;

  /// Stores the trimmed address and its pending change in one unit of work
  /// and returns its id; it is the primary only when the customer has none.
  /// Throws [ValidationFailure] for fields the server would refuse and
  /// [NotFoundFailure] for a missing customer.
  Future<String> execute({
    required String customerId,
    required AddressDetails details,
  }) async {
    final clean = details.trimmed()..validate();
    return _transaction(() => _addressRepo.add(customerId, clean));
  }
}
