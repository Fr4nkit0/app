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
    await db.into(db.customerTable).insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
          ),
        );
    await db.into(db.productTable).insert(
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
    double price,
    String from, {
    String? to,
    int? serverId,
    String? reason,
  }) => db.into(db.customerAgreementTable).insert(
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

  testWidgets('lists agreements with status and the unsynced hint', (tester) async {
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

  testWidgets('the form refuses more than two decimals', (tester) async {
    await pumpTab(tester);

    await tester.tap(find.text('Nuevo acuerdo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agreement_product')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agua 20L').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('agreement_price')), '1200,555');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Usá hasta 2 decimales'), findsOneWidget);
    expect(await db.select(db.customerAgreementTable).get(), isEmpty);
    await unmount(tester);
  });
}
