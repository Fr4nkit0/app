import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/payments/presentation/widgets/amount_field.dart';

void main() {
  testWidgets(
    'AmountField shows label, prefix, numeric keyboard and onChanged',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [MarilinTokens.light]),
          home: Scaffold(
            body: AmountField(
              label: 'Efectivo',
              controller: controller,
              onChanged: changes.add,
            ),
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(find.text('Efectivo'), findsOneWidget);
      expect(field.decoration!.prefixText, '\$ ');
      expect(
        field.keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );

      await tester.enterText(find.byType(TextField), '125.5');
      expect(changes, ['125.5']);
      expect(controller.text, '125.5');
    },
  );
}
