import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_address.repository.dart';

/// The driver drops a delivery address the customer no longer uses.
class DisableAddressUseCase {
  const DisableAddressUseCase({
    required CustomerAddressRepository addressRepo,
    required TransactionRunner transaction,
  }) : _addressRepo = addressRepo,
       _transaction = transaction;

  final CustomerAddressRepository _addressRepo;
  final TransactionRunner _transaction;

  /// Disables the address and queues it in one unit of work. The server
  /// refuses to disable the primary, so this does too: another address has
  /// to become the primary first. Throws [ValidationFailure] for the primary
  /// and [NotFoundFailure] for a missing or disabled address.
  Future<void> execute(String addressId) => _transaction(() async {
    final address = await _addressRepo.findEnabled(addressId);
    if (address == null) throw const NotFoundFailure('address');
    if (address.isPrimary) {
      throw const ValidationFailure(
        'La dirección principal no se puede dar de baja.',
      );
    }
    await _addressRepo.disable(addressId);
  });
}
