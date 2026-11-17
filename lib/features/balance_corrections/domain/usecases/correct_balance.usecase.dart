import 'package:uuid/uuid.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/balance_corrections/data/repositories/balance_correction.repository.dart';
import 'package:app/features/balance_corrections/domain/models/balance_correction.dart';

String _uuidV4() => const Uuid().v4();

/// The driver counted the real debt or container custody of a customer
/// and corrects the balance the device shows to it. Applied at once; the
/// server flags it for the admin's review.
class CorrectBalanceUseCase {
  const CorrectBalanceUseCase({
    required BalanceCorrectionRepository repo,
    required TransactionRunner transaction,
    DateTime Function() now = DateTime.now,
    String Function() newId = _uuidV4,
  }) : _repo = repo,
       _transaction = transaction,
       _now = now,
       _newId = newId;

  static const minReasonLength = 3;
  static const maxReasonLength = 500;

  static const reasonTooShort =
      'Escribí el motivo de la corrección (al menos 3 caracteres).';
  static const reasonTooLong = 'El motivo no puede superar los 500 caracteres.';
  static const invalidContainers =
      'Los envases contados deben ser un número entero mayor o igual a cero.';
  static const missingContainerType = 'Elegí el tipo de envase a corregir.';

  final BalanceCorrectionRepository _repo;
  final TransactionRunner _transaction;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Records that [customerId]'s [target] really is [counted] (containers:
  /// of [containerType]), moves the shown balance there and queues the
  /// correction, in one unit of work. Throws [ValidationFailure] for a
  /// reason outside 3..500 characters, a container count that is not a
  /// whole number >= 0, or a container correction without its type.
  Future<BalanceCorrection> execute({
    required String customerId,
    required BalanceTarget target,
    required num counted,
    required String reason,
    String? containerType,
    String? visitId,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.length < minReasonLength) {
      throw const ValidationFailure(reasonTooShort);
    }
    if (trimmed.length > maxReasonLength) {
      throw const ValidationFailure(reasonTooLong);
    }
    final double value;
    switch (target) {
      case BalanceTarget.containers:
        if (containerType == null || containerType.isEmpty) {
          throw const ValidationFailure(missingContainerType);
        }
        if (counted < 0 || counted != counted.roundToDouble()) {
          throw const ValidationFailure(invalidContainers);
        }
        value = counted.toDouble();
      case BalanceTarget.debt:
        value = (counted * 100).round() / 100;
    }

    return _transaction(() async {
      final seen = await _repo.shownBalance(
        customerId,
        target,
        containerType: containerType,
      );
      final correction = BalanceCorrection(
        id: _newId(),
        customerId: customerId,
        target: target,
        containerType: target == BalanceTarget.containers
            ? containerType
            : null,
        counted: value,
        seenBalance: seen,
        reason: trimmed,
        correctedAt: _now(),
        visitId: visitId,
      );
      await _repo.record(correction);
      return correction;
    });
  }
}
