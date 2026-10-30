import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step3_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/container_types.dart';
import '../../../../support/real_fonts.dart';

class _PreparedDraft extends SaleDraft {
  _PreparedDraft(this._initial);

  final SaleDraftState _initial;

  @override
  SaleDraftState build() => _initial;
}

SaleDraftState _draft({double debt = 0}) => SaleDraftState(
  customer: Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
    debtAmount: debt,
  ),
  items: [
    SaleItem(
      product: const Product(
        id: 'p-1',
        name: 'Agua 20L',
        unitLabel: 'bidón',
        price: 1500,
      ),
      quantity: 2,
    ),
  ],
);

void main() {
  setUpAll(() async {
    expect(
      await loadRealFonts(),
      isTrue,
      reason: 'Roboto was not found in the Flutter SDK cache',
    );
  });

  Future<void> pumpScreen(WidgetTester tester, SaleDraftState draft) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleDraftProvider.overrideWith(() => _PreparedDraft(draft)),
          customerContainerBalancesProvider.overrideWith(
            (ref, id) => Stream.value(const <CustomerContainerBalance>[]),
          ),
          containerTypesProvider.overrideWith(
            (ref) => Stream.value(catalogContainerTypes),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SaleStep3Screen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('reads total, then payment method, then order detail', (
    tester,
  ) async {
    await pumpScreen(tester, _draft());

    final total = tester.getTopLeft(find.text('A cobrar')).dy;
    final method = tester.getTopLeft(find.text('Forma de pago')).dy;
    final order = tester.getTopLeft(find.text('Pedido').last).dy;
    expect(total, lessThan(method));
    expect(method, lessThan(order));
    expect(find.text('FORMA DE PAGO'), findsNothing);
  });

  testWidgets('the amount is 40sp', (tester) async {
    await pumpScreen(tester, _draft());

    final amount = tester.widget<Text>(find.text('\$3.000').first);
    expect(amount.style?.fontSize, 40);
  });

  testWidgets('previous debt is a quiet line, not a chip', (tester) async {
    await pumpScreen(tester, _draft(debt: 2500));
    expect(find.text('Debe \$2.500 de antes'), findsOneWidget);
    expect(find.textContaining('Deuda previa'), findsNothing);
  });

  testWidgets('no debt line without debt', (tester) async {
    await pumpScreen(tester, _draft());
    expect(find.textContaining('de antes'), findsNothing);
    expect(find.textContaining('Deuda previa'), findsNothing);
  });

  testWidgets('payment cards are 72dp InkWell buttons without emoji', (
    tester,
  ) async {
    await pumpScreen(tester, _draft());

    for (final method in PaymentMethod.gridMethods) {
      final card = find.ancestor(
        of: find.text(method.label),
        matching: find.byType(Material),
      );
      expect(card, findsWidgets);
      final inkWell = find.ancestor(
        of: find.text(method.label),
        matching: find.byType(InkWell),
      );
      expect(inkWell, findsOneWidget, reason: method.label);
      expect(
        tester.getSize(inkWell).height,
        greaterThanOrEqualTo(72),
        reason: method.label,
      );
    }
    const emoji = ['💵', '🏦', '🔀', '🗓️', '🚛'];
    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data);
    for (final e in emoji) {
      expect(texts, isNot(contains(e)));
    }
  });

  testWidgets('the order card has no Total row', (tester) async {
    await pumpScreen(tester, _draft());
    expect(find.text('Total'), findsNothing);
    expect(find.text('Kiosco Norte'), findsOneWidget); // header subtitle only
  });

  testWidgets('quick chips fill the mixed fields with the total', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      _draft().copyWith(paymentMethod: PaymentMethod.mixed),
    );

    String textOf(String label) => tester
        .widget<TextField>(find.widgetWithText(TextField, label))
        .controller!
        .text;

    await tester.tap(find.text('Todo en efectivo'));
    await tester.pump();
    expect(textOf('Efectivo'), '3000');
    expect(textOf('Transferencia'), '0');

    await tester.tap(find.text('Todo por transferencia'));
    await tester.pump();
    expect(textOf('Efectivo'), '0');
    expect(textOf('Transferencia'), '3000');
  });
}
