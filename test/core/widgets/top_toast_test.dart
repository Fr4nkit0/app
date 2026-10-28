import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHost(WidgetTester tester, void Function(BuildContext) fire) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => fire(context),
              child: const Text('fire'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('showError keeps its message for 5 seconds', (tester) async {
    await pumpHost(tester, (c) => TopToast.showError(c, 'Algo falló'));
    await tester.tap(find.text('fire'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Algo falló'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Algo falló'), findsNothing);
  });

  testWidgets('showSuccess accepts a custom duration', (tester) async {
    await pumpHost(
      tester,
      (c) => TopToast.showSuccess(
        c,
        'Listo',
        duration: const Duration(seconds: 1),
      ),
    );
    await tester.tap(find.text('fire'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Listo'), findsNothing);
  });
}
