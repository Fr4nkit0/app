import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_address.repository.dart';
import 'package:app/features/customers/domain/models/address_details.dart';

/// The driver corrects the typed fields of one delivery address.
class EditAddressUseCase {
  const EditAddressUseCase({
    required CustomerAddressRepository addressRepo,
    required TransactionRunner transaction,
  }) : _addressRepo = addressRepo,
       _transaction = transaction;

  final CustomerAddressRepository _addressRepo;
  final TransactionRunner _transaction;

  /// Writes the trimmed fields and queues the address in one unit of work;
  /// the push sends them with its `modified_at` and the server keeps the
  /// latest write. Throws [ValidationFailure] for fields the server would
  /// refuse and [NotFoundFailure] for a missing or disabled address.
  Future<void> execute({
    required String addressId,
    required AddressDetails details,
  }) async {
    final clean = details.trimmed()..validate();
    return _transaction(() => _addressRepo.edit(addressId, clean));
  }
}
