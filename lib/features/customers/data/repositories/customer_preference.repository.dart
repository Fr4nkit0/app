import 'package:app/core/errors/domain_failure.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';

/// The delivery preferences of a customer: one per day and start, disabled
/// ones included. Writes queue their pending change; run them inside a use
/// case's unit of work.
abstract class CustomerPreferenceRepository {
  /// The customer's enabled preferences, by day and then start.
  Stream<List<CustomerPreference>> watchForCustomer(String customerId);

  /// The enabled preference [preferenceId] and its customer, or null when
  /// it is missing or disabled.
  Future<({CustomerPreference preference, String customerId})?> findEnabled(
    String preferenceId,
  );

  /// The preference of [customerId], enabled or not, that takes the day and
  /// start of [details], other than [exceptId].
  Future<({String id, bool enabled})?> findInSlot(
    String customerId,
    PreferenceDetails details, {
    String? exceptId,
  });

  /// An enabled preference of [customerId], other than [exceptId], whose
  /// window overlaps [details].
  Future<PreferenceDetails?> findOverlapping(
    String customerId,
    PreferenceDetails details, {
    String? exceptId,
  });

  /// Adds an enabled preference to [customerId] and returns its id. Throws
  /// [NotFoundFailure] when the customer does not exist.
  Future<String> add(String customerId, PreferenceDetails details);

  /// Replaces the day and window of [preferenceId].
  Future<void> edit(String preferenceId, PreferenceDetails details);

  /// Enables the disabled [preferenceId] again with the window of
  /// [details].
  Future<void> enable(String preferenceId, PreferenceDetails details);

  /// Disables [preferenceId], keeping its day and window.
  Future<void> disable(String preferenceId);
}
