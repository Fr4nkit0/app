import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/presentation/widgets/customer_agreements_tab.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
          ),
        );
    await db
        .into(db.productTable)
        .insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('p-1'),
            name: 'Agua 20L',
            price: 1500,
          ),
        );
  });
  tearDown(() async {
    await db.close();
  });

  Future<void> pumpTab(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CustomerAgreementsTab(customerId: 'c-1'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  // Drift schedules a zero-duration timer when a watched query is cancelled.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  Future<void> insert(
    String id,
    int price,
    String from, {
    String? to,
    int? serverId,
    String? reason,
  }) => db
      .into(db.customerAgreementTable)
      .insert(
        CustomerAgreementTableCompanion.insert(
          agreementId: drift.Value(id),
          customerId: 'c-1',
          productId: 'p-1',
          unitPrice: price,
          validFrom: from,
          validTo: drift.Value(to),
          reason: drift.Value(reason),
          serverId: drift.Value(serverId),
        ),
      );

  testWidgets('shows the empty state and the create action', (tester) async {
    await pumpTab(tester);

    expect(find.text('Sin acuerdos'), findsOneWidget);
    expect(find.text('Nuevo acuerdo'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('lists agreements with status and the unsynced hint', (
    tester,
  ) async {
    await insert('a-old', 1000, '2020-01-01', to: '2020-02-01', serverId: 1);
    await insert('a-now', 1200, '2020-03-01', serverId: 2, reason: 'Mayorista');
    await insert('a-next', 1300, '2999-01-01');

    await pumpTab(tester);

    expect(find.text('Vigente'), findsOneWidget);
    expect(find.text('Finalizado'), findsOneWidget);
    expect(find.text('Futuro'), findsOneWidget);
    expect(find.text('Agua 20L'), findsNWidgets(3));
    expect(find.text('\$1.200'), findsOneWidget);
    expect(find.text('Mayorista'), findsOneWidget);
    expect(find.text('Pendiente de sincronizar'), findsOneWidget);
    // In force first.
    expect(
      tester.getTopLeft(find.text('Vigente')).dy,
      lessThan(tester.getTopLeft(find.text('Finalizado')).dy),
    );
    await unmount(tester);
  });

  testWidgets('the form creates an agreement', (tester) async {
    await pumpTab(tester);

    await tester.tap(find.text('Nuevo acuerdo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agreement_product')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agua 20L').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('agreement_price')), '1100');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final row = await db.select(db.customerAgreementTable).getSingle();
    expect(row.unitPrice, 1100);
    expect(row.productId, 'p-1');
    expect(find.text('Pendiente de sincronizar'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the form refuses a price of zero', (tester) async {
    await pumpTab(tester);

    await tester.tap(find.text('Nuevo acuerdo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agreement_product')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agua 20L').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('agreement_price')), '0');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresá un precio mayor a 0'), findsOneWidget);
    expect(await db.select(db.customerAgreementTable).get(), isEmpty);
    await unmount(tester);
  });

  testWidgets('the price field takes whole pesos grouped by thousands', (
    tester,
  ) async {
    await pumpTab(tester);

    await tester.tap(find.text('Nuevo acuerdo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agreement_product')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agua 20L').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('agreement_price')), '1200,5');
    await tester.pump();

    final price = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('agreement_price')),
        matching: find.byType(TextField),
      ),
    );
    expect(price.keyboardType, TextInputType.number);
    expect(price.controller!.text, '12.005');
    await unmount(tester);
  });

  Future<void> openActions(WidgetTester tester, String action) async {
    await tester.tap(find.byTooltip('Opciones de acuerdo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  Future<CustomerAgreementTableData?> rowOf(String id) => (db.select(
    db.customerAgreementTable,
  )..where((t) => t.agreementId.equals(id))).getSingleOrNull();

  testWidgets('an ended agreement offers no actions', (tester) async {
    await insert('a-old', 1000, '2020-01-01', to: '2020-02-01', serverId: 1);

    await pumpTab(tester);

    expect(find.byTooltip('Opciones de acuerdo'), findsNothing);
    await unmount(tester);
  });

  testWidgets('edit opens the form prefilled with the product locked and '
      'saves in place', (tester) async {
    await insert('a-next', 1200, '2999-01-01', reason: 'Mayorista');
    await pumpTab(tester);

    await openActions(tester, 'Editar');

    expect(find.text('Editar acuerdo'), findsOneWidget);
    final price = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('agreement_price')),
        matching: find.byType(EditableText),
      ),
    );
    expect(price.controller.text, '1.200');
    final reason = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('agreement_reason')),
        matching: find.byType(EditableText),
      ),
    );
    expect(reason.controller.text, 'Mayorista');
    expect(find.text('01/01/2999'), findsWidgets);
    final product = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byKey(const Key('agreement_product')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    expect(product.onChanged, isNull);
    expect(product.value, 'p-1');

    await tester.enterText(find.byKey(const Key('agreement_price')), '1350');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final rows = await db.select(db.customerAgreementTable).get();
    expect(rows, hasLength(1));
    expect(rows.single.unitPrice, 1350);
    expect(rows.single.productId, 'p-1');
    expect(rows.single.reason, 'Mayorista');
    expect(find.text('Acuerdo actualizado'), findsOneWidget);
    expect(find.text('Editar acuerdo'), findsNothing);
    await unmount(tester);
  });

  testWidgets('delete asks first and keeps the agreement on cancel', (
    tester,
  ) async {
    await insert('a-now', 1200, '2020-03-01', serverId: 2);
    await pumpTab(tester);

    await openActions(tester, 'Eliminar');

    expect(find.text('¿Eliminar acuerdo?'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Agua 20L'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect((await rowOf('a-now'))!.enabled, isTrue);
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    expect(find.text('Vigente'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('delete on confirm disables a synced agreement and hides it', (
    tester,
  ) async {
    await insert('a-now', 1200, '2020-03-01', serverId: 2);
    await pumpTab(tester);

    await openActions(tester, 'Eliminar');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await tester.pumpAndSettle();

    expect((await rowOf('a-now'))!.enabled, isFalse);
    expect(find.text('Acuerdo eliminado'), findsOneWidget);
    expect(find.text('Sin acuerdos'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('delete on confirm removes an unsynced agreement', (
    tester,
  ) async {
    await insert('a-next', 1300, '2999-01-01');
    await pumpTab(tester);

    await openActions(tester, 'Eliminar');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(await rowOf('a-next'), isNull);
    expect(find.text('Sin acuerdos'), findsOneWidget);
    await unmount(tester);
  });
}
