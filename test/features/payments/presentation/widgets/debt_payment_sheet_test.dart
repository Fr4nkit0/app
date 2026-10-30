import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/payments/domain/models/payment_split.dart';
import 'package:app/features/payments/presentation/widgets/debt_payment_sheet.dart';

PaymentSplit? _result;
bool _closed = false;

Future<void> _open(WidgetTester tester) async {
  _result = null;
  _closed = false;
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [MarilinTokens.light]),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              _result = await showModalBottomSheet<PaymentSplit>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const DebtPaymentSheet(totalDebt: 1000),
              );
              _closed = true;
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, String method) async {
  await tester.tap(find.byKey(ValueKey('method-card-$method')));
  await tester.pumpAndSettle();
}

Finder _payFull() => find.widgetWithText(FilledButton, 'Pagar deuda completa');
Finder _register() =>
    find.widgetWithText(OutlinedButton, 'Registrar monto ingresado');

void main() {
  testWidgets('full cash returns Efectivo with the whole debt', (tester) async {
    await _open(tester);
    await _select(tester, 'Efectivo');
    await tester.tap(_payFull());
    await tester.pumpAndSettle();

    expect(_result, const PaymentSplit(cash: 1000));
  });

  testWidgets('full transfer returns Transferencia with the whole debt', (
    tester,
  ) async {
    await _open(tester);
    await _select(tester, 'Transferencia');
    await tester.tap(_payFull());
    await tester.pumpAndSettle();

    expect(_result, const PaymentSplit(transfer: 1000));
  });

  testWidgets('partial amount returns the typed amount', (tester) async {
    await _open(tester);
    await _select(tester, 'Efectivo');
    await tester.enterText(find.byType(TextField), '400,50');
    await tester.pump();
    await tester.tap(_register());
    await tester.pumpAndSettle();

    expect(_result, const PaymentSplit(cash: 400.5));
  });

  testWidgets('mixed covering the debt enables Pagar deuda completa', (
    tester,
  ) async {
    await _open(tester);
    await _select(tester, 'Mixto');
    expect(tester.widget<FilledButton>(_payFull()).onPressed, isNull);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '600');
    await tester.enterText(fields.at(1), '300');
    await tester.pump();
    expect(tester.widget<FilledButton>(_payFull()).onPressed, isNull);

    await tester.enterText(fields.at(1), '400');
    await tester.pump();
    await tester.tap(_payFull());
    await tester.pumpAndSettle();

    expect(_result, const PaymentSplit(cash: 600, transfer: 400));
  });

  testWidgets('cancel returns null', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(_closed, isTrue);
    expect(_result, isNull);
  });

  testWidgets('method cards are at least 64dp tall and tappable', (
    tester,
  ) async {
    await _open(tester);
    for (final method in ['Efectivo', 'Transferencia', 'Mixto']) {
      final card = find.byKey(ValueKey('method-card-$method'));
      expect(tester.getSize(card).height, greaterThanOrEqualTo(64));
      expect(
        find.descendant(of: card, matching: find.byType(InkWell)),
        findsOneWidget,
      );
    }
  });

  testWidgets('renders no emoji text', (tester) async {
    await _open(tester);
    await _select(tester, 'Mixto');
    final emoji = RegExp(
      r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true,
    );
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(emoji.hasMatch(text.data ?? ''), isFalse, reason: text.data);
    }
  });
}
