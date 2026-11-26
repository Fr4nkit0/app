import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_agreement.repository.dart';

/// The driver removes an agreement: it stops pricing sales and is no longer
/// listed. A disabled agreement cannot be enabled again.
class DeleteCustomerAgreementUseCase {
  const DeleteCustomerAgreementUseCase({
    required CustomerAgreementRepository agreementRepo,
    required TransactionRunner transaction,
  }) : _agreementRepo = agreementRepo,
       _transaction = transaction;

  final CustomerAgreementRepository _agreementRepo;
  final TransactionRunner _transaction;

  /// In one unit of work, disables a synced agreement and queues it, or
  /// removes one the server never got together with its queued changes.
  /// An unsynced agreement a sale already used is disabled instead: the
  /// server must still get it, or it rejects that sale.
  /// Throws [NotFoundFailure] for a missing or disabled agreement.
  Future<void> execute(String agreementId) => _transaction(() async {
    final current = await _agreementRepo.findEnabled(agreementId);
    if (current == null) throw const NotFoundFailure('agreement');
    if (current.isSynced || await _agreementRepo.isUsedBySale(agreementId)) {
      await _agreementRepo.disable(agreementId);
    } else {
      await _agreementRepo.deleteUnsynced(agreementId);
    }
  });
}
