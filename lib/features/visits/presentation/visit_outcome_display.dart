import 'package:flutter/material.dart';

import 'package:app/core/utils/money_formatter.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/domain/models/visit_summary.dart';

/// Icon for an outcome, picked by its server code; unknown codes fall back on
/// whether the outcome reschedules the stop.
IconData visitOutcomeIcon(VisitOutcome outcome) {
  switch (outcome.code) {
    case 'absent':
      return Icons.person_off_outlined;
    case 'refused':
      return Icons.block_flipped;
    case 'reschedule':
      return Icons.calendar_today_outlined;
  }
  return outcome.triggersReschedule
      ? Icons.calendar_today_outlined
      : Icons.check_circle_outline;
}

/// An absent customer cannot have returned containers or paid, and a visit
/// with returns or payments cannot be rescheduled.
bool isVisitOutcomeEnabled(
  VisitOutcome outcome, {
  required bool hasReturns,
  required bool hasPayments,
}) {
  final hasActivity = hasReturns || hasPayments;
  if (outcome.code == 'absent' || outcome.triggersReschedule) {
    return !hasActivity;
  }
  return true;
}

/// One line with how a visit ended and its amounts, e.g. "Venta $5.700 ·
/// Efectivo" or "No quiso · Cobró $2.000 · Devolvió 3". A reschedule is left
/// to the reschedule label, which names the new time. Null when there is
/// nothing to show.
String? visitSummaryLine(VisitSummary visit) {
  final outcome = visit.outcome;
  final parts = [
    if (visit.hasSales) ...[
      'Venta ${formatMoney(visit.salesTotal)}',
      for (final method in visit.saleMethods) method.label,
    ] else if (outcome != null && !outcome.triggersReschedule)
      outcome.name,
    if (visit.collected > 0) 'Cobró ${formatMoney(visit.collected)}',
    if (visit.returned > 0) 'Devolvió ${visit.returned}',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// [time] as "HH:mm".
String formatClockTime(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';
