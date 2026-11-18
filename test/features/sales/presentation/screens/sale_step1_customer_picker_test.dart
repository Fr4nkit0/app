import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/products/presentation/providers/product_list_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';

/// The real repository, recording the paged reads the picker asks for.
class _SpyCustomerRepository extends DriftCustomerRepository {
  _SpyCustomerRepository(super.db);

  final pages = <(int, int)>[];
  final searches = <String>[];
  int failuresLeft = 0;

  @override
  Future<List<Customer>> getCustomersPage({
    required int page,
    required int pageSize,
  }) {
    pages.add((page, pageSize));
    if (failuresLeft > 0) {
      failuresLeft--;
      return Future.error(StateError('database unavailable'));
    }
    return super.getCustomersPage(page: page, pageSize: pageSize);
  }

  @override
  Future<List<Customer>> searchCustomers({
    required String query,
    required int page,
    required int pageSize,
  }) {
    searches.add(query);
    return super.searchCustomers(query: query, page: page, pageSize: pageSize);
  }
}

/// Lets the in-memory database answer; its queries run outside fake time.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  late AppDatabase db;
  late _SpyCustomerRepository repository;

  // 25 customers: more than two pages of 10.
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    for (var i = 1; i <= 25; i++) {
      final n = i.toString().padLeft(2, '0');
      await db
          .into(db.customerTable)
          .insert(
            CustomerTableCompanion.insert(
              customerId: drift.Value('c-$n'),
              name: 'Cliente $n',
              phone: drift.Value('38740000$n'),
            ),
          );
    }
    repository = _SpyCustomerRepository(db);
  });
  tearDown(() => db.close());

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        customerRepositoryProvider.overrideWithValue(repository),
        customerProductListProvider.overrideWith(
          (ref, id) => Stream.value(const <Product>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SaleStep1Screen(),
        ),
      ),
    );
    await settle(tester);
    return container;
  }

  Future<void> unmount(WidgetTester tester) async {
    // Drift schedules a zero-duration timer when a watched query is cancelled.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  testWidgets('opens on the first page of customers and loads the next one '
      'on scroll', (tester) async {
    await pump(tester);

    expect(repository.pages, [(0, 10)]);
    expect(find.text('TODOS LOS CLIENTES'), findsOneWidget);
    expect(find.text('Cliente 01'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await settle(tester);

    expect(repository.pages, containsAllInOrder([(0, 10), (1, 10)]));
    expect(find.text('Cliente 11', skipOffstage: false), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('typing a name searches the repository', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'cliente 07');
    await settle(tester);

    expect(repository.searches, contains('cliente 07'));
    expect(find.text('Cliente 07'), findsOneWidget);
    expect(find.text('Cliente 01'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a phone number no longer finds the customer', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), '3874000007');
    await settle(tester);

    expect(find.text('Cliente 07'), findsNothing);
    expect(find.text('Sin resultados para "3874000007"'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('shows no Frecuentes section', (tester) async {
    await pump(tester);

    expect(find.text('FRECUENTES'), findsNothing);
    await unmount(tester);
  });

  testWidgets('choosing a customer selects it for the sale, and changing it '
      'clears the search', (tester) async {
    final container = await pump(tester);

    await tester.enterText(find.byType(TextField), 'cliente 07');
    await settle(tester);
    await tester.tap(find.text('Cliente 07'));
    await settle(tester);

    expect(container.read(saleDraftProvider).customer?.id, 'c-07');

    await tester.tap(find.text('Cambiar'));
    await settle(tester);

    expect(container.read(saleDraftProvider).customer, isNull);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(find.text('Cliente 01'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a failed first load offers a retry that reloads the list', (
    tester,
  ) async {
    // A tall screen leaves the error room to show.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository.failuresLeft = 1;
    await pump(tester);

    expect(find.byType(ErrorState), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await settle(tester);

    expect(find.byType(ErrorState), findsNothing);
    expect(find.text('Cliente 01'), findsOneWidget);
    await unmount(tester);
  });
}
