import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/presentation/visit_outcome_display.dart';

VisitOutcome _outcome(String? code, {bool triggersReschedule = false}) =>
    VisitOutcome(id: 1, code: code, name: 'x', triggersReschedule: triggersReschedule);

void main() {
  group('visitOutcomeIcon', () {
    test('uses the icon of each known code', () {
      expect(visitOutcomeIcon(_outcome('absent')), Icons.person_off_outlined);
      expect(visitOutcomeIcon(_outcome('refused')), Icons.block_flipped);
      expect(
        visitOutcomeIcon(_outcome('reschedule', triggersReschedule: true)),
        Icons.calendar_today_outlined,
      );
    });

    test('falls back on the reschedule flag for an unknown or missing code', () {
      expect(visitOutcomeIcon(_outcome(null, triggersReschedule: true)), Icons.calendar_today_outlined);
      expect(visitOutcomeIcon(_outcome('other')), Icons.check_circle_outline);
    });
  });

  group('isVisitOutcomeEnabled', () {
    test('an absent customer cannot have returned containers or paid', () {
      expect(isVisitOutcomeEnabled(_outcome('absent'), hasReturns: true, hasPayments: false), isFalse);
      expect(isVisitOutcomeEnabled(_outcome('absent'), hasReturns: false, hasPayments: true), isFalse);
      expect(isVisitOutcomeEnabled(_outcome('absent'), hasReturns: false, hasPayments: false), isTrue);
    });

    test('rescheduling is not possible after returns or payments', () {
      final reschedule = _outcome('reschedule', triggersReschedule: true);
      expect(isVisitOutcomeEnabled(reschedule, hasReturns: true, hasPayments: false), isFalse);
      expect(isVisitOutcomeEnabled(reschedule, hasReturns: false, hasPayments: false), isTrue);
    });

    test('a refusal is always possible', () {
      expect(isVisitOutcomeEnabled(_outcome('refused'), hasReturns: true, hasPayments: true), isTrue);
    });
  });
}
