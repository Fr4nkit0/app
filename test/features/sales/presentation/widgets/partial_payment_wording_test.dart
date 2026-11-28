import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/sales/presentation/widgets/partial_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// S11: the unpaid note and the partial confirmation say the unpaid amount
/// adds to a previous debt.
void main() {
  group('unpaidNoteText', () {
    test('without previous debt keeps "Queda debiendo"', () {
      expect(unpaidNoteText(500), 'Queda debiendo \$500');
      expect(unpaidNoteText(500, previousDebt: 0), 'Queda debiendo \$500');
    });

    test('with previous debt says it adds and shows the total', () {
      expect(
        unpaidNoteText(500, previousDebt: 500),
        'Suma \$500 a su deuda de \$500. Deuda total: \$1.000',
      );
    });
  });

  group('partialPaymentQuestion', () {
    test('without previous debt keeps the current question', () {
      expect(
        partialPaymentQuestion(500),
        'El cliente queda debiendo \$500. ¿Confirmás?',
      );
    });

    test('with previous debt says it adds and shows the total', () {
      expect(
        partialPaymentQuestion(500, previousDebt: 32500),
        'Suma \$500 a su deuda de \$32.500. Deuda total: \$33.000. '
        '¿Confirmás?',
      );
    });
  });

  testWidgets('UnpaidAmountNote shows the wording for previous debt', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Column(
            children: [
              UnpaidAmountNote(unpaid: 500),
              UnpaidAmountNote(unpaid: 500, previousDebt: 500),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Queda debiendo \$500'), findsOneWidget);
    expect(
      find.text('Suma \$500 a su deuda de \$500. Deuda total: \$1.000'),
      findsOneWidget,
    );
  });
}
