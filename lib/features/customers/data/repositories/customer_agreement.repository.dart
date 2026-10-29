import 'package:app/features/customers/domain/models/customer_agreement.dart';

abstract class CustomerAgreementRepository {
  static const maxReasonLength = 500;

  /// The customer's agreements: in force first, then future, then ended;
  /// most recent start first within each group.
  Stream<List<CustomerAgreement>> watchForCustomer(
    String customerId, {
    DateTime? today,
  });

  /// Stores a new agreement and queues it for the server; it prices sales
  /// from [validFrom] on. Dates are `YYYY-MM-DD`. Returns the agreement id.
  /// Run it inside the use case's unit of work.
  Future<String> create({
    required String customerId,
    required String productId,
    required double unitPrice,
    required String validFrom,
    String? validTo,
    String? reason,
  });
}
