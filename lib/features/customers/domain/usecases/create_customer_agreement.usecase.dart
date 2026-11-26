import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_agreement.repository.dart';
import 'package:app/features/customers/domain/models/agreement_terms.dart';

/// A customer gets a special price for a product from [validFrom] on.
class CreateCustomerAgreementUseCase {
  const CreateCustomerAgreementUseCase({
    required CustomerAgreementRepository agreementRepo,
    required TransactionRunner transaction,
  }) : _agreementRepo = agreementRepo,
       _transaction = transaction;

  final CustomerAgreementRepository _agreementRepo;
  final TransactionRunner _transaction;

  /// Stores the agreement and its pending change in one unit of work and
  /// returns its id. Dates are `YYYY-MM-DD`. Throws [ValidationFailure] for
  /// a price that is not positive or has more than 2 decimals, an end before
  /// the start, or a reason over [CustomerAgreementRepository.maxReasonLength].
  Future<String> execute({
    required String customerId,
    required String productId,
    required double unitPrice,
    required String validFrom,
    String? validTo,
    String? reason,
  }) async {
    final terms = AgreementTerms(
      unitPrice: unitPrice,
      validFrom: validFrom,
      validTo: validTo,
      reason: reason,
    ).normalized()..validate();
    return _transaction(
      () => _agreementRepo.create(
        customerId: customerId,
        productId: productId,
        unitPrice: terms.unitPrice,
        validFrom: terms.validFrom,
        validTo: terms.validTo,
        reason: terms.reason,
      ),
    );
  }
}
