import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/widgets/new_customer_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('is labelled for TalkBack', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: NewCustomerButton(onTap: () => taps++)),
      ),
    );

    await tester.tap(find.byTooltip('Nuevo cliente'));
    expect(taps, 1);
  });
}
