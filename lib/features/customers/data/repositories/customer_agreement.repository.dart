import 'package:app/features/customers/domain/models/agreement_terms.dart';
import 'package:app/features/customers/domain/models/customer_agreement.dart';

/// Every write stamps the agreement's modification time and queues one
/// `customer_agreement` change. Run writes inside the use case's unit of
/// work.
abstract class CustomerAgreementRepository {
  static const maxReasonLength = AgreementTerms.maxReasonLength;

  /// The customer's agreements: in force first, then future, then ended;
  /// most recent start first within each group.
  Stream<List<CustomerAgreement>> watchForCustomer(
    String customerId, {
    DateTime? today,
  });

  /// The enabled agreement [agreementId], or null when it is missing or
  /// disabled. Its status is the one on [today].
  Future<CustomerAgreement?> findEnabled(String agreementId, {DateTime? today});

  /// Stores a new agreement and queues it for the server; it prices sales
  /// from [validFrom] on. Dates are `YYYY-MM-DD`. Returns the agreement id.
  Future<String> create({
    required String customerId,
    required String productId,
    required int unitPrice,
    required String validFrom,
    String? validTo,
    String? reason,
  });

  /// Writes [terms] on the agreement itself and queues an update.
  Future<void> edit(String agreementId, AgreementTerms terms);

  /// Disables the agreement: it stops pricing sales and is no longer
  /// listed. Queues an update.
  Future<void> disable(String agreementId);

  /// Removes an agreement the server never got, with its queued changes, so
  /// nothing about it is pushed. Leaves a synced agreement alone.
  Future<void> deleteUnsynced(String agreementId);

  /// Whether a sale line stored on the device references the agreement.
  Future<bool> isUsedBySale(String agreementId);

  /// Closes the agreement and creates a new one for the same customer and
  /// product with [terms]; returns the new id. The old one ends the day
  /// before [today], or is disabled when it started on [today]. Its update
  /// is queued before the new one's insert, so the server closes it first.
  Future<String> replace(
    String agreementId,
    AgreementTerms terms, {
    required DateTime today,
  });
}
