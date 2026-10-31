import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_preference.repository.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';

/// The driver adds a delivery day and window to a customer.
class AddPreferenceUseCase {
  const AddPreferenceUseCase({
    required CustomerPreferenceRepository preferenceRepo,
    required TransactionRunner transaction,
  }) : _preferenceRepo = preferenceRepo,
       _transaction = transaction;

  static const slotTaken =
      'El cliente ya tiene una preferencia para ese día y horario.';

  /// The refusal naming the [existing] window a new one overlaps.
  static String overlapping(PreferenceDetails existing) =>
      'Se superpone con ${existing.label}.';

  final CustomerPreferenceRepository _preferenceRepo;
  final TransactionRunner _transaction;

  /// Stores the preference and its pending change in one unit of work and
  /// returns its id. The server keeps one preference per day and start,
  /// disabled ones included, so a disabled preference in that slot is
  /// enabled again with the new window instead of adding a second one.
  /// Throws [ValidationFailure] for a window the server would refuse, a
  /// slot already enabled or a window overlapping another enabled one, and
  /// [NotFoundFailure] for a missing customer.
  Future<String> execute({
    required String customerId,
    required PreferenceDetails details,
  }) async {
    final clean = details.normalized()..validate();
    return _transaction(() async {
      final taken = await _preferenceRepo.findInSlot(customerId, clean);
      if (taken != null && taken.enabled) {
        throw const ValidationFailure(slotTaken);
      }
      final overlapped = await _preferenceRepo.findOverlapping(
        customerId,
        clean,
      );
      if (overlapped != null) {
        throw ValidationFailure(overlapping(overlapped));
      }
      if (taken == null) return _preferenceRepo.add(customerId, clean);
      await _preferenceRepo.enable(taken.id, clean);
      return taken.id;
    });
  }
}
