import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_preference.repository.dart';

/// The driver drops a delivery day the customer no longer wants.
class DisablePreferenceUseCase {
  const DisablePreferenceUseCase({
    required CustomerPreferenceRepository preferenceRepo,
    required TransactionRunner transaction,
  }) : _preferenceRepo = preferenceRepo,
       _transaction = transaction;

  final CustomerPreferenceRepository _preferenceRepo;
  final TransactionRunner _transaction;

  /// Disables the preference and queues it in one unit of work; adding the
  /// same day and start later enables it again. Throws [NotFoundFailure]
  /// for a missing or disabled preference.
  Future<void> execute(String preferenceId) => _transaction(() async {
    if (await _preferenceRepo.findEnabled(preferenceId) == null) {
      throw const NotFoundFailure('preference');
    }
    await _preferenceRepo.disable(preferenceId);
  });
}
