import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_agreement.repository.dart';

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
    final trimmed = reason?.trim();
    final cleanReason = trimmed == null || trimmed.isEmpty ? null : trimmed;
    if (unitPrice <= 0) {
      throw const ValidationFailure('El precio debe ser mayor a 0.');
    }
    // The server keeps two decimals and rejects more, which would strand the
    // agreement in the queue while it already prices sales here.
    if ((unitPrice * 100).roundToDouble() / 100 != unitPrice) {
      throw const ValidationFailure('El precio admite hasta 2 decimales.');
    }
    if (validTo != null && validTo.compareTo(validFrom) < 0) {
      throw const ValidationFailure(
        'La fecha de fin no puede ser anterior al inicio.',
      );
    }
    if (cleanReason != null &&
        cleanReason.length > CustomerAgreementRepository.maxReasonLength) {
      throw const ValidationFailure(
        'El motivo admite hasta ${CustomerAgreementRepository.maxReasonLength} caracteres.',
      );
    }
    return _transaction(
      () => _agreementRepo.create(
        customerId: customerId,
        productId: productId,
        unitPrice: unitPrice,
        validFrom: validFrom,
        validTo: validTo,
        reason: cleanReason,
      ),
    );
  }
}
