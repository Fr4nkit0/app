import 'package:flutter/material.dart';

import 'package:app/features/visits/domain/models/visit_outcome.dart';

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
