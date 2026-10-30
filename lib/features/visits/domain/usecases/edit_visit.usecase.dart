import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/visits/data/repositories/visit.repository.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';

class EditVisitUseCase {
  EditVisitUseCase({
    required VisitRepository visitRepo,
    required TransactionRunner transaction,
    DateTime Function() now = DateTime.now,
  }) : _visitRepo = visitRepo,
       _transaction = transaction,
       _now = now;

  final VisitRepository _visitRepo;
  final TransactionRunner _transaction;
  final DateTime Function() _now;

  /// Changes the outcome and notes (null clears them) of a visit of today
  /// without a sale, in one unit of work; the push sends it as an edit.
  ///
  /// The stop keeps its status: every outcome but a reschedule closes it as
  /// done, and a reschedule (which adds a stop) is neither editable nor a
  /// valid new outcome. Throws [ValidationFailure] when the visit cannot be
  /// edited and [NotFoundFailure] when it does not exist.
  Future<void> execute({
    required String visitId,
    required int outcomeId,
    String? notes,
  }) async {
    final now = _now();
    await _transaction(() async {
      final visit = await _visitRepo.findVisit(visitId);
      if (visit == null) throw const NotFoundFailure('visit');
      if (!_sameDay(visit.arrivedAt, now)) {
        throw const ValidationFailure(
          'Solo se pueden editar las visitas de hoy.',
        );
      }
      if (visit.visitType == VisitType.sale ||
          await _visitRepo.stopHasSales(visit.routeStopId)) {
        throw const ValidationFailure(
          'Una visita con venta no se puede editar.',
        );
      }
      final current = visit.outcomeId == null
          ? null
          : await _visitRepo.findOutcome(visit.outcomeId!);
      if (current?.triggersReschedule ?? false) {
        throw const ValidationFailure(
          'Una visita reprogramada no se puede editar.',
        );
      }
      final next = await _visitRepo.findOutcome(outcomeId);
      if (next == null || next.triggersReschedule) {
        throw const ValidationFailure('Elegí un resultado sin reprogramar.');
      }

      await _visitRepo.editVisit(
        visitId,
        outcomeId: outcomeId,
        observations: notes,
        modifiedAt: now,
      );
    });
  }

  static bool _sameDay(DateTime a, DateTime b) {
    final x = a.toLocal();
    final y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }
}
