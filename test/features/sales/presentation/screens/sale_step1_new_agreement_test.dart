import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_usecase_providers.dart';
import 'package:app/features/products/presentation/providers/product_list_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';

/// The driver can agree a price with the customer without leaving the sale,
/// and the sale in progress is charged at that price.

final _customer = Customer(
  id: 'c-1',
  name: 'Kiosco Norte',
  addresses: const [],
  preferences: const [],
);

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Lets the in-memory database answer; its queries run outside fake time.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'c-1',
            serverId: const drift.Value(10),
          ),
        );
    await db
        .into(db.productTable)
        .insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('p-1'),
            name: 'Bidón 20L',
            price: 6500,
            serverId: const drift.Value(21),
          ),
        );
  });
  tearDown(() => db.close());

  /// Nueva Venta with the customer already picked.
  Future<ProviderContainer> pumpSale(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    // As in the app, other screens already watch their own data when the
    // sale opens; the sale prices must not depend on what they watch.
    container.listen(productListProvider, (_, _) {});
    await _settle(tester);
    container.read(saleDraftProvider.notifier).selectCustomer(_customer);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SaleStep1Screen(),
        ),
      ),
    );
    await _settle(tester);
    return container;
  }

  /// An agreement in force at $5.000 for the sale customer.
  Future<void> createAgreement(WidgetTester tester) => tester.runAsync(
    () => ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)])
        .read(createCustomerAgreementUseCaseProvider)
        .execute(
          customerId: 'c-1',
          productId: 'p-1',
          unitPrice: 5000,
          validFrom: _today(),
          validTo: null,
          reason: '',
        ),
  );

  Future<void> unmount(WidgetTester tester) async {
    // Drift schedules a zero-duration timer when a watched query is cancelled.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  testWidgets('«Nuevo acuerdo» next to the products opens the agreement form '
      'for the sale customer', (tester) async {
    await pumpSale(tester);
    // A list-price product has no agreement to change.
    expect(find.text('Editar acuerdo'), findsNothing);
    expect(find.text('Eliminar acuerdo'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Nuevo acuerdo'));
    await _settle(tester);

    expect(find.byKey(const Key('agreement_product')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a line already in the sale takes the price of an agreement '
      'created meanwhile', (tester) async {
    final container = await pumpSale(tester);

    await tester.tap(find.bySemanticsLabel('Agregar una Bidón 20L'));
    await _settle(tester);
    await tester.tap(find.bySemanticsLabel('Agregar una Bidón 20L'));
    await _settle(tester);
    expect(container.read(saleDraftProvider).total, 13000);

    await tester.runAsync(
      () => container
          .read(createCustomerAgreementUseCaseProvider)
          .execute(
            customerId: 'c-1',
            productId: 'p-1',
            unitPrice: 5000,
            validFrom: _today(),
            validTo: null,
            reason: '',
          ),
    );
    await _settle(tester);

    expect(find.text(r'$5.000 c/u · acuerdo'), findsOneWidget);
    final draft = container.read(saleDraftProvider);
    expect(draft.items.single.quantity, 2);
    expect(draft.items.single.product.price, 5000);
    expect(draft.items.single.product.agreementUuid, isNotNull);
    expect(draft.total, 10000);
    await unmount(tester);
  });

  testWidgets('saving a new agreement in the form shows its price on the '
      'product at once', (tester) async {
    final container = await pumpSale(tester);
    await tester.tap(find.bySemanticsLabel('Agregar una Bidón 20L'));
    await _settle(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Nuevo acuerdo'));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('agreement_product')));
    await _settle(tester);
    await tester.tap(find.text('Bidón 20L').last);
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('agreement_price')), '5000');
    await tester.tap(find.text('Guardar'));
    await _settle(tester);

    expect(find.text('Acuerdo creado'), findsOneWidget);
    expect(find.text(r'$5.000 c/u · acuerdo'), findsOneWidget);
    expect(find.text(r'$6.500 c/u'), findsNothing);
    expect(container.read(saleDraftProvider).total, 5000);
    await tester.pump(const Duration(seconds: 5));
    await _settle(tester);
    await unmount(tester);
  });

  testWidgets('saving an edited agreement in the form shows its price on the '
      'product at once', (tester) async {
    await createAgreement(tester);
    final container = await pumpSale(tester);
    await tester.tap(find.bySemanticsLabel('Agregar una Bidón 20L'));
    await _settle(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Editar acuerdo'));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('agreement_price')), '4000');
    await tester.tap(find.text('Guardar'));
    await _settle(tester);

    expect(find.text('Acuerdo actualizado'), findsOneWidget);
    expect(find.text(r'$4.000 c/u · acuerdo'), findsOneWidget);
    expect(find.text(r'$5.000 c/u · acuerdo'), findsNothing);
    expect(container.read(saleDraftProvider).total, 4000);
    await tester.pump(const Duration(seconds: 5));
    await _settle(tester);
    await unmount(tester);
  });

  testWidgets('«Editar acuerdo» on an agreement-priced product opens its '
      'agreement prefilled', (tester) async {
    await createAgreement(tester);
    await pumpSale(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Editar acuerdo'));
    await _settle(tester);

    expect(find.byKey(const Key('agreement_product')), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '5.000'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('«Eliminar acuerdo» asks, deletes it and brings the loaded '
      'line back to the list price', (tester) async {
    await createAgreement(tester);
    final container = await pumpSale(tester);
    await tester.tap(find.bySemanticsLabel('Agregar una Bidón 20L'));
    await _settle(tester);
    expect(container.read(saleDraftProvider).total, 5000);

    await tester.tap(find.widgetWithText(TextButton, 'Eliminar acuerdo'));
    await _settle(tester);
    // Cancelling keeps the agreement.
    await tester.tap(find.text('Cancelar'));
    await _settle(tester);
    expect(container.read(saleDraftProvider).total, 5000);
    expect(find.text(r'$5.000 c/u · acuerdo'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Eliminar acuerdo'));
    await _settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await _settle(tester);

    expect(find.text('Acuerdo eliminado'), findsOneWidget);
    expect(find.text(r'$6.500 c/u'), findsOneWidget);
    expect(find.text('Eliminar acuerdo'), findsNothing);
    final draft = container.read(saleDraftProvider);
    expect(draft.items.single.quantity, 1);
    expect(draft.items.single.product.hasAgreement, isFalse);
    expect(draft.total, 6500);
    // Lets the toast go.
    await tester.pump(const Duration(seconds: 5));
    await _settle(tester);
    await unmount(tester);
  });
}
