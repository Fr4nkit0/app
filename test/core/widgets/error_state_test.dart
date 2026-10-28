import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/widgets/error_state.dart';

void main() {
  testWidgets('shows title, message and a 52dp retry that calls onRetry', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorState(
            title: 'No pudimos cargar la ruta',
            message: 'Revisá la conexión y reintentá.',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.text('No pudimos cargar la ruta'), findsOneWidget);
    expect(find.text('Revisá la conexión y reintentá.'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);

    final retry = find.widgetWithText(OutlinedButton, 'Reintentar');
    expect(retry, findsOneWidget);
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(52));
    await tester.tap(retry);
    expect(retries, 1);
  });
}
