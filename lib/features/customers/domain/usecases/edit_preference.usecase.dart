import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_preference.repository.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/customers/domain/usecases/add_preference.usecase.dart';

/// The driver corrects the day or window of one delivery preference.
class EditPreferenceUseCase {
  const EditPreferenceUseCase({
    required CustomerPreferenceRepository preferenceRepo,
    required TransactionRunner transaction,
  }) : _preferenceRepo = preferenceRepo,
       _transaction = transaction;

  final CustomerPreferenceRepository _preferenceRepo;
  final TransactionRunner _transaction;

  /// Writes the day and window and queues the preference in one unit of
  /// work. Moving it onto the slot of another preference, even a disabled
  /// one, is refused like the server does. Throws [ValidationFailure] for a
  /// refused window or slot and [NotFoundFailure] for a missing or disabled
  /// preference.
  Future<void> execute({
    required String preferenceId,
    required PreferenceDetails details,
  }) async {
    final clean = details.normalized()..validate();
    return _transaction(() async {
      final current = await _preferenceRepo.findEnabled(preferenceId);
      if (current == null) throw const NotFoundFailure('preference');
      final taken = await _preferenceRepo.findInSlot(
        current.customerId,
        clean,
        exceptId: preferenceId,
      );
      if (taken != null) {
        throw const ValidationFailure(AddPreferenceUseCase.slotTaken);
      }
      await _preferenceRepo.edit(preferenceId, clean);
    });
  }
}
