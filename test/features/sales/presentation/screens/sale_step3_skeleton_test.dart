import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/domain/models/truck_skeletons.dart';
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

import '../../../../support/container_types.dart';
import '../../../../support/real_fonts.dart';

class _FakeRegisterSale implements RegisterSaleUseCase {
  List<ContainerMovement>? movements;

  @override
  Future<void> execute(
    Sale sale, {
    Payment? payment,
    List<ContainerMovement>? containerMovements,
    double debtAmount = 0,
  }) async {
    movements = containerMovements;
  }
}

/// A sale of water without returnable containers, ready to confirm.
class _PreparedDraft extends SaleDraft {
  @override
  SaleDraftState build() => SaleDraftState(
    customer: Customer(
      id: 'c-1',
      name: 'Kiosco Norte',
      addresses: const [],
      preferences: const [],
    ),
    items: const [
      SaleItem(
        product: Product(
          id: 'p-1',
          name: 'Agua 500ml',
          unitLabel: 'u',
          price: 500,
        ),
        quantity: 2,
      ),
    ],
    paymentMethod: PaymentMethod.cash,
  );
}

const _skeleton = ContainerType(
  id: 9,
  code: 'ESQUELETO',
  label: 'Esqueleto para sifones de soda',
);

void main() {
  setUpAll(() async => expect(await loadRealFonts(), isTrue));

  late _FakeRegisterSale fake;
  late ProviderContainer container;

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<ContainerType> catalog = const [...catalogContainerTypes, _skeleton],
    int skeletonBalance = 1,
    TruckSkeletons? truck,
  }) async {
    fake = _FakeRegisterSale();
    await tester.binding.setSurfaceSize(const Size(360, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    container = ProviderContainer(
      overrides: [
        saleDraftProvider.overrideWith(_PreparedDraft.new),
        registerSaleUseCaseProvider.overrideWithValue(fake),
        customerContainerBalancesProvider.overrideWith(
          (ref, id) => Stream.value([
            CustomerContainerBalance(
              customerId: id,
              containerType: 'ESQUELETO',
              quantity: skeletonBalance,
            ),
          ]),
        ),
        containerTypesProvider.overrideWith((ref) => Stream.value(catalog)),
        truckSkeletonsProvider.overrideWith((ref) => Stream.value(truck)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SaleStep3Screen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder stepper(String label, String tooltip) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
    matching: find.byTooltip(tooltip),
  );

  testWidgets('the skeleton section starts closed with the balance', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Esqueleto'), findsOneWidget);
    expect(find.text('Saldo del cliente: 1'), findsOneWidget);
    expect(find.text('Entregar al cliente'), findsNothing);
    expect(find.text('Retirar del cliente'), findsNothing);
  });

  testWidgets('opening it shows both skeleton rows at 0', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Esqueleto'));
    await tester.pumpAndSettle();

    expect(find.text('Entregar al cliente'), findsOneWidget);
    expect(find.text('Retirar del cliente'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('Retirar goes past the balance and reaches the sale', (
    tester,
  ) async {
    await pumpScreen(tester, skeletonBalance: 1);

    await tester.tap(find.text('Esqueleto'));
    await tester.pumpAndSettle();
    await tester.tap(stepper('Retirar del cliente', 'Sumar'));
    await tester.pump();
    await tester.tap(stepper('Retirar del cliente', 'Sumar'));
    await tester.pump();
    await tester.tap(stepper('Entregar al cliente', 'Sumar'));
    await tester.pumpAndSettle();

    final draft = container.read(saleDraftProvider);
    expect(draft.skeletonReturned, 2);
    expect(draft.skeletonDelivered, 1);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    // The success toast keeps animating: flush it instead of settling.
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    final skeleton = fake.movements!.singleWhere(
      (m) => m.containerType == 'ESQUELETO',
    );
    expect(skeleton.deliveredQuantity, 1);
    expect(skeleton.returnedQuantity, 2);
  });

  testWidgets('Restar does not go below 0', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Esqueleto'));
    await tester.pumpAndSettle();
    await tester.tap(
      stepper('Entregar al cliente', 'Restar'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(container.read(saleDraftProvider).skeletonDelivered, 0);
  });

  testWidgets('no section without ESQUELETO in the catalog', (tester) async {
    await pumpScreen(tester, catalog: catalogContainerTypes);

    expect(find.text('Esqueleto'), findsNothing);
    expect(find.textContaining('Saldo del cliente'), findsNothing);
  });

  testWidgets('without skeletons the sale sends no ESQUELETO movement', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    // The success toast keeps animating: flush it instead of settling.
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    expect(
      (fake.movements ?? const []).where((m) => m.containerType == 'ESQUELETO'),
      isEmpty,
    );
  });

  group('on the truck', () {
    Color? colorOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style?.color;

    testWidgets('shows what is left on the truck when opened', (tester) async {
      await pumpScreen(
        tester,
        truck: const TruckSkeletons(loaded: 6, remaining: 1, hasActivity: true),
      );

      await tester.tap(find.text('Esqueleto'));
      await tester.pumpAndSettle();

      expect(find.text('En el camión: 1'), findsOneWidget);
      final tokens = Theme.of(
        tester.element(find.text('En el camión: 1')),
      ).extension<MarilinTokens>()!;
      expect(colorOf(tester, 'En el camión: 1'), tokens.textMuted);
    });

    testWidgets('delivering past it warns and the sale still goes '
        'through', (tester) async {
      await pumpScreen(
        tester,
        truck: const TruckSkeletons(loaded: 6, remaining: 1, hasActivity: true),
      );

      await tester.tap(find.text('Esqueleto'));
      await tester.pumpAndSettle();
      await tester.tap(stepper('Entregar al cliente', 'Sumar'));
      await tester.pump();
      await tester.tap(stepper('Entregar al cliente', 'Sumar'));
      await tester.pumpAndSettle();

      final tokens = Theme.of(
        tester.element(find.text('En el camión: 1')),
      ).extension<MarilinTokens>()!;
      expect(colorOf(tester, 'En el camión: 1'), tokens.destructive);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      // The success toast keeps animating: flush it instead of settling.
      await tester.pump();
      await tester.pump(const Duration(seconds: 10));

      expect(
        fake.movements!
            .singleWhere((m) => m.containerType == 'ESQUELETO')
            .deliveredQuantity,
        2,
      );
    });

    testWidgets('nothing about the truck without a route today', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Esqueleto'));
      await tester.pumpAndSettle();

      expect(find.textContaining('En el camión'), findsNothing);
    });
  });
}
