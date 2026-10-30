import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_address.repository.dart';

/// The driver picks the address deliveries go to; a customer keeps exactly
/// one enabled primary address.
class SetPrimaryAddressUseCase {
  const SetPrimaryAddressUseCase({
    required CustomerAddressRepository addressRepo,
    required TransactionRunner transaction,
  }) : _addressRepo = addressRepo,
       _transaction = transaction;

  final CustomerAddressRepository _addressRepo;
  final TransactionRunner _transaction;

  /// Makes the address the primary and unsets the previous one in one unit
  /// of work; the current primary changes nothing. Throws [NotFoundFailure]
  /// for a missing or disabled address.
  Future<void> execute(String addressId) => _transaction(() async {
    final address = await _addressRepo.findEnabled(addressId);
    if (address == null) throw const NotFoundFailure('address');
    if (address.isPrimary) return;
    await _addressRepo.setPrimary(addressId);
  });
}
