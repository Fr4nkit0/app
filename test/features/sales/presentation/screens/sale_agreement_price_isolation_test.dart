import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';

/// A customer's agreement price must not follow the driver to the next
/// customer: a sale opened from a visit and left must leave the Venta tab
/// pricing the next customer at its own price.

final _withAgreement = Customer(
  id: 'c-1',
  name: 'Romina Cardozo',
  addresses: const [],
  preferences: const [],
);
final _listPrice = Customer(
  id: 'c-2',
  name: 'Kiosco Norte',
  addresses: const [],
  preferences: const [],
);

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
    for (final (id, serverId) in [('c-1', 10), ('c-2', 11)]) {
      await db
          .into(db.customerTable)
          .insert(
            CustomerTableCompanion.insert(
              customerId: drift.Value(id),
              name: id,
              serverId: drift.Value(serverId),
            ),
          );
    }
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
    // Only the first customer has an agreement on the product.
    await db
        .into(db.customerAgreementTable)
        .insert(
          CustomerAgreementTableCompanion.insert(
            customerId: 'c-1',
            productId: 'p-1',
            unitPrice: 5000,
            validFrom: '2020-01-01',
            serverId: const drift.Value(31),
          ),
        );
  });
  tearDown(() => db.close());

  /// The shell: the Venta tab's Nueva Venta under a visit button that opens
  /// its own Nueva Venta for the agreement customer, as the visit does.
  Future<ProviderContainer> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      container
                          .read(saleDraftProvider.notifier)
                          .selectCustomer(_withAgreement, visitId: 'stop-1');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SaleStep1Screen(),
                        ),
                      );
                    },
                    child: const Text('Venta desde la visita'),
                  ),
                  const Expanded(child: SaleStep1Screen()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
    return container;
  }

  Future<void> openVisitSale(WidgetTester tester) async {
    await tester.tap(find.text('Venta desde la visita'));
    await _settle(tester);
    // The visit sale shows the agreement price.
    expect(find.text(r'$5.000 c/u · acuerdo'), findsOneWidget);
  }

  Future<void> leaveVisitSale(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Volver'));
    await _settle(tester);
  }

  /// The driver picks the list-price customer in the Venta tab, adds one
  /// product, and the line and the stored sale carry the list price (the
  /// push sends the stored price unchanged, see sale_draft_pricing_test).
  Future<void> expectListPriceSale(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    expect(container.read(saleDraftProvider).isEmpty, isTrue);
    container.read(saleDraftProvider.notifier).selectCustomer(_listPrice);
    await _settle(tester);

    expect(find.text(r'$6.500 c/u'), findsOneWidget);
    expect(find.textContaining(r'$5.000'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Agregar una Bidón 20L'));
    await _settle(tester);

    final draft = container.read(saleDraftProvider);
    expect(draft.customer!.id, 'c-2');
    expect(draft.visitId, isNull);
    expect(draft.items.single.product.price, 6500);
    expect(draft.items.single.product.agreementId, isNull);
    expect(draft.total, 6500);
  }

  Future<void> unmount(WidgetTester tester) async {
    // Drift schedules a zero-duration timer when a watched query is cancelled.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  testWidgets('leaving a visit sale untouched, the next customer is sold at '
      'its list price', (tester) async {
    final container = await pumpShell(tester);

    await openVisitSale(tester);
    await leaveVisitSale(tester);

    expect(find.text('¿Descartar la venta en curso?'), findsNothing);
    await expectListPriceSale(tester, container);
    await unmount(tester);
  });

  testWidgets('discarding a visit sale with agreement-priced products, the '
      'next customer is sold at its list price', (tester) async {
    final container = await pumpShell(tester);

    await openVisitSale(tester);
    await tester.tap(find.bySemanticsLabel('Agregar una Bidón 20L').last);
    await _settle(tester);
    expect(container.read(saleDraftProvider).total, 5000);

    await leaveVisitSale(tester);
    await tester.tap(find.text('Descartar'));
    await _settle(tester);

    await expectListPriceSale(tester, container);
    await unmount(tester);
  });
}
