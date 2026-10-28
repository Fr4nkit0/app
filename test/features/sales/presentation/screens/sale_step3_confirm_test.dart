import 'dart:async';

import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';
import 'package:app/features/sales/presentation/providers/register_sale_usecase_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step3_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/real_fonts.dart';

class _FakeRegisterSale implements RegisterSaleUseCase {
  Completer<Resource<void>> completer = Completer<Resource<void>>();
  int calls = 0;

  @override
  Future<Resource<void>> execute(
    Sale sale, {
    Payment? payment,
    List<ContainerMovement>? containerMovements,
  }) {
    calls++;
    return completer.future;
  }
}

class _PreparedDraft extends SaleDraft {
  @override
  SaleDraftState build() => SaleDraftState(
    customer: Customer(
      id: 'c-1',
      name: 'Kiosco Norte',
      addresses: const [],
      preferences: const [],
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
    paymentMethod: PaymentMethod.cash,
  );
}

void main() {
  setUpAll(() async {
    expect(
      await loadRealFonts(),
      isTrue,
      reason: 'Roboto was not found in the Flutter SDK cache',
    );
  });

  late _FakeRegisterSale fake;

  Future<void> pumpScreen(WidgetTester tester) async {
    fake = _FakeRegisterSale();
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleDraftProvider.overrideWith(_PreparedDraft.new),
          registerSaleUseCaseProvider.overrideWithValue(fake),
          customerContainerBalancesProvider.overrideWith(
            (ref, id) => Stream.value(const <CustomerContainerBalance>[]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SaleStep3Screen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  final confirmButton = find.widgetWithText(FilledButton, 'Confirmar');
  final backButton = find.widgetWithText(OutlinedButton, 'Atrás');

  testWidgets('a second tap while pending runs the sale once and locks the '
      'footer', (tester) async {
    await pumpScreen(tester);

    await tester.tap(confirmButton);
    await tester.pump();
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();

    expect(fake.calls, 1);
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.text('Confirmar'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.widget<OutlinedButton>(backButton).onPressed, isNull);

    fake.completer.complete(const Resource.success(null));
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('a failed sale keeps the screen, re-enables Confirmar and '
      'shows a friendly toast', (tester) async {
    await pumpScreen(tester);

    await tester.tap(confirmButton);
    await tester.pump();
    fake.completer.complete(Resource.error(Exception('db exploded')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SaleStep3Screen), findsOneWidget);
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNotNull);
    expect(tester.widget<OutlinedButton>(backButton).onPressed, isNotNull);
    expect(find.text('No se guardó la venta. Reintentá.'), findsOneWidget);
    expect(find.textContaining('db exploded'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpAndSettle(const Duration(seconds: 6));
  });

  testWidgets('a saved sale without a visit goes back to the first route '
      'with the success toast', (tester) async {
    await pumpScreen(tester);

    await tester.tap(confirmButton);
    await tester.pump();
    fake.completer.complete(const Resource.success(null));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.byType(SaleStep3Screen), findsNothing);
    expect(find.text('Venta registrada con éxito'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
