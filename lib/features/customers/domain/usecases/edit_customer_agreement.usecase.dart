import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_agreement.repository.dart';
import 'package:app/features/customers/domain/models/agreement_terms.dart';

/// The driver changes the price, the days or the reason of an agreement;
/// its product and customer never change.
class EditCustomerAgreementUseCase {
  const EditCustomerAgreementUseCase({
    required CustomerAgreementRepository agreementRepo,
    required TransactionRunner transaction,
    DateTime Function() now = DateTime.now,
  }) : _agreementRepo = agreementRepo,
       _transaction = transaction,
       _now = now;

  final CustomerAgreementRepository _agreementRepo;
  final TransactionRunner _transaction;
  final DateTime Function() _now;

  /// Applies the terms in one unit of work and returns the id of the
  /// agreement that now carries them.
  ///
  /// A synced agreement already in force (started today or earlier) that
  /// gets a new price or start is replaced: sales may have used it, so the
  /// server keeps it and a new agreement takes the new terms. Anything else
  /// is edited in place. Throws [ValidationFailure] like
  /// `CreateCustomerAgreementUseCase` and [NotFoundFailure] for a missing or
  /// disabled agreement.
  Future<String> execute({
    required String agreementId,
    required int unitPrice,
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
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    return _transaction(() async {
      final current = await _agreementRepo.findEnabled(
        agreementId,
        today: today,
      );
      if (current == null) throw const NotFoundFailure('agreement');
      final started = current.validFrom.compareTo(_dateOnly(today)) <= 0;
      final priceOrStartChanged =
          current.unitPrice != terms.unitPrice ||
          current.validFrom != terms.validFrom;
      if (started && current.isSynced && priceOrStartChanged) {
        return _agreementRepo.replace(
          agreementId,
          _fromToday(terms, _dateOnly(today)),
          today: today,
        );
      }
      await _agreementRepo.edit(agreementId, terms);
      return agreementId;
    });
  }

  /// The terms of a replacement: it only prices future sales, so it starts
  /// today at the earliest, and an end before today is refused.
  static AgreementTerms _fromToday(AgreementTerms terms, String today) {
    final end = terms.validTo;
    if (end != null && end.compareTo(today) < 0) {
      throw const ValidationFailure(
        'La fecha de fin no puede ser anterior a hoy.',
      );
    }
    return AgreementTerms(
      unitPrice: terms.unitPrice,
      validFrom: terms.validFrom.compareTo(today) < 0 ? today : terms.validFrom,
      validTo: terms.validTo,
      reason: terms.reason,
    );
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
