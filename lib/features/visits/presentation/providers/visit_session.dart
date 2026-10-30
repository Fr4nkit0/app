import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/providers/clock_provider.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';
import 'package:app/features/visits/domain/reschedule_time.dart';
import 'package:app/features/visits/presentation/providers/complete_visit_usecase_provider.dart';
import 'package:app/features/visits/presentation/visit_outcome_display.dart';

const _unset = Object();

/// What the driver chose at a stop and what was already recorded there.
@immutable
class VisitSessionState {
  const VisitSessionState({
    this.isSaleSelected = false,
    this.selectedOutcome,
    this.rescheduleTime,
    this.rescheduleError,
    this.isClosing = false,
    this.hasSales = false,
    this.hasReturns = false,
    this.hasPayments = false,
  });

  /// The driver picked "sale" instead of a visit without sale.
  final bool isSaleSelected;

  /// Why the visit ends without a sale; null until the driver picks one.
  final VisitOutcome? selectedOutcome;

  /// The time of the new stop when rescheduling, always later today.
  final TimeOfDay? rescheduleTime;

  /// Why [rescheduleTime] is not allowed, shown on the time field.
  final RescheduleTimeError? rescheduleError;

  /// The close is being saved.
  final bool isClosing;

  final bool hasSales;
  final bool hasReturns;
  final bool hasPayments;

  bool get isRescheduleSelected => selectedOutcome?.triggersReschedule ?? false;

  bool isOutcomeEnabled(VisitOutcome outcome) => isVisitOutcomeEnabled(
    outcome,
    hasReturns: hasReturns,
    hasPayments: hasPayments,
  );

  /// The primary action opens the sale flow instead of closing the visit.
  bool get startsSale => !hasSales && isSaleSelected;

  /// A visit closes with its sales or, without them, with an outcome.
  bool get canClose => hasSales || selectedOutcome != null;

  /// Only a visit without sales can be rescheduled.
  bool get triggersReschedule => !hasSales && isRescheduleSelected;

  StopStatus get nextStatus =>
      triggersReschedule ? StopStatus.absent : StopStatus.done;

  VisitType get visitType => isSaleSelected ? VisitType.sale : VisitType.visit;

  VisitSessionState copyWith({
    bool? isSaleSelected,
    Object? selectedOutcome = _unset,
    Object? rescheduleTime = _unset,
    Object? rescheduleError = _unset,
    bool? isClosing,
    bool? hasSales,
    bool? hasReturns,
    bool? hasPayments,
  }) => VisitSessionState(
    isSaleSelected: isSaleSelected ?? this.isSaleSelected,
    selectedOutcome: identical(selectedOutcome, _unset)
        ? this.selectedOutcome
        : selectedOutcome as VisitOutcome?,
    rescheduleTime: identical(rescheduleTime, _unset)
        ? this.rescheduleTime
        : rescheduleTime as TimeOfDay?,
    rescheduleError: identical(rescheduleError, _unset)
        ? this.rescheduleError
        : rescheduleError as RescheduleTimeError?,
    isClosing: isClosing ?? this.isClosing,
    hasSales: hasSales ?? this.hasSales,
    hasReturns: hasReturns ?? this.hasReturns,
    hasPayments: hasPayments ?? this.hasPayments,
  );
}

/// How [VisitSession.close] ended.
sealed class VisitCloseResult {
  const VisitCloseResult();
}

/// The visit with its sales was closed.
final class VisitClosedWithSales extends VisitCloseResult {
  const VisitClosedWithSales();
}

/// The stop was rescheduled to [at].
final class VisitRescheduled extends VisitCloseResult {
  const VisitRescheduled(this.at);

  final DateTime at;
}

/// The visit without sale was closed with its outcome.
final class VisitClosed extends VisitCloseResult {
  const VisitClosed();
}

/// Nothing was saved: the visit cannot close yet, is already closing, or the
/// reschedule time is not allowed (see [VisitSessionState.rescheduleError]).
final class VisitCloseRejected extends VisitCloseResult {
  const VisitCloseRejected();
}

/// Saving failed with [error]; the visit can be closed again.
final class VisitCloseFailed extends VisitCloseResult {
  const VisitCloseFailed(this.error);

  final Object error;
}

/// The decisions of the visit to one stop, keyed by the stop's id: which
/// outcomes are possible, when it can close, how the stop ends and whether
/// the reschedule time is allowed.
class VisitSession extends Notifier<VisitSessionState> {
  VisitSession(this.stopId);

  final String stopId;

  DateTime _now() => ref.read(clockProvider)();

  @override
  VisitSessionState build() {
    void sync(Object? _, Object? _) => state = _withActivity(state);
    ref.listen(stopSalesProvider(stopId), sync);
    ref.listen(visitMovementsProvider(stopId), sync);
    ref.listen(visitPaymentsProvider(stopId), sync);
    return _withActivity(const VisitSessionState());
  }

  /// [current] with what is recorded at the stop; returns or payments clear
  /// a selected reschedule, which they no longer allow.
  VisitSessionState _withActivity(VisitSessionState current) {
    final next = current.copyWith(
      hasSales: ref
          .read(stopSalesProvider(stopId))
          .maybeWhen(
            // A cancelled sale no longer makes it a sale visit.
            data: (sales) => sales.any((sale) => !sale.isCancelled),
            orElse: () => false,
          ),
      hasReturns: ref
          .read(visitMovementsProvider(stopId))
          .maybeWhen(
            data: (movements) => movements.any((m) => m.returnedQuantity > 0),
            orElse: () => false,
          ),
      hasPayments: ref
          .read(visitPaymentsProvider(stopId))
          .maybeWhen(
            data: (payments) => payments.isNotEmpty,
            orElse: () => false,
          ),
    );
    if ((next.hasReturns || next.hasPayments) && next.isRescheduleSelected) {
      return next.copyWith(selectedOutcome: null);
    }
    return next;
  }

  void selectSaleMode() => state = state.copyWith(isSaleSelected: true);

  void selectVisitMode() => state = state.copyWith(isSaleSelected: false);

  void selectOutcome(VisitOutcome outcome) {
    if (!state.isOutcomeEnabled(outcome)) return;
    state = state.copyWith(selectedOutcome: outcome);
  }

  /// The time the picker opens at: the chosen one, else an hour from now.
  TimeOfDay initialRescheduleTime() =>
      state.rescheduleTime ??
      TimeOfDay.fromDateTime(_now().add(const Duration(hours: 1)));

  void setRescheduleTime(TimeOfDay time) {
    final now = _now();
    state = state.copyWith(
      rescheduleTime: time,
      rescheduleError: checkRescheduleTime(now: now, at: _today(now, time)),
    );
  }

  /// Records the visit and closes, or reschedules, its stop.
  Future<VisitCloseResult> close({String observations = ''}) async {
    final current = state;
    final stop = ref.read(routeStopByIdProvider(stopId));
    if (current.isClosing || !current.canClose || stop == null) {
      return const VisitCloseRejected();
    }

    DateTime? rescheduleAt;
    if (current.triggersReschedule) {
      final now = _now();
      final time = current.rescheduleTime;
      rescheduleAt = time == null ? null : _today(now, time);
      final error = rescheduleAt == null
          ? RescheduleTimeError.notLater
          : checkRescheduleTime(now: now, at: rescheduleAt);
      if (error != null) {
        state = state.copyWith(rescheduleError: error);
        return const VisitCloseRejected();
      }
    }

    state = state.copyWith(isClosing: true);
    try {
      await ref
          .read(completeVisitUseCaseProvider)
          .execute(
            stopId: stop.id,
            customerId: stop.customer.id,
            visitType: current.visitType,
            nextStatus: current.nextStatus,
            outcomeId: current.hasSales ? null : current.selectedOutcome?.id,
            observations: observations.isNotEmpty ? observations : null,
            rescheduleAt: rescheduleAt,
          );
    } catch (error) {
      if (!ref.mounted) return VisitCloseFailed(error);
      // The time can stop being valid while the close is saved.
      final rescheduleError = error is ValidationFailure && rescheduleAt != null
          ? checkRescheduleTime(now: _now(), at: rescheduleAt)
          : null;
      if (rescheduleError != null) {
        state = state.copyWith(
          isClosing: false,
          rescheduleError: rescheduleError,
        );
        return const VisitCloseRejected();
      }
      state = state.copyWith(isClosing: false);
      return VisitCloseFailed(error);
    }

    if (current.hasSales) return const VisitClosedWithSales();
    if (rescheduleAt != null) return VisitRescheduled(rescheduleAt);
    return const VisitClosed();
  }

  static DateTime _today(DateTime now, TimeOfDay time) =>
      DateTime(now.year, now.month, now.day, time.hour, time.minute);
}

final visitSessionProvider = NotifierProvider.autoDispose
    .family<VisitSession, VisitSessionState, String>(VisitSession.new);
