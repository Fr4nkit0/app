import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/widgets/customer_name_text.dart';

void main() {
  Future<void> pump(WidgetTester tester, {int? number}) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: CustomerNameText(
          name: 'Kiosco Norte',
          number: number,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    ),
  );

  testWidgets('shows the name followed by the number', (tester) async {
    await pump(tester, number: 128);

    expect(find.text('Kiosco Norte  #128', findRichText: true), findsOneWidget);
  });

  testWidgets('a customer not synced yet shows only the name', (tester) async {
    await pump(tester);

    expect(find.text('Kiosco Norte', findRichText: true), findsOneWidget);
    expect(find.textContaining('#', findRichText: true), findsNothing);
  });
}
