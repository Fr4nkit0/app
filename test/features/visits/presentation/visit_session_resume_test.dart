import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/providers/clock_provider.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/providers/pending_change_repository_provider.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/visits/presentation/screens/visit_screen.dart';

import '../../../support/container_types.dart';

final _customer = Customer(
  id: 'c-1',
  name: 'Tolaba',
  addresses: const [],
  preferences: const [],
);

final _stop = RouteStop(
  id: 's-1',
  customer: _customer,
  status: StopStatus.pending,
  scheduledAt: DateTime(2026, 10, 29, 9),
);

final _sale = Sale(
  id: 'sale-1',
  customer: _customer,
  items: const [
    SaleItem(
      product: Product(
        id: 'p-1',
        name: 'Bidón 20L',
        unitLabel: 'u',
        price: 1900,
      ),
      quantity: 1,
    ),
  ],
  total: 1900,
  paymentMethod: PaymentMethod.cash,
  date: DateTime(2026, 10, 29, 10),
  visitId: 's-1',
);

const _absent = VisitOutcome(
  id: 1,
  code: 'absent',
  name: 'Ausente',
  triggersReschedule: false,
);

void main() {
  // The sale flow covers the visit, which pauses its subscriptions, and
  // reloads the visit's records; they reload when the visit shows again,
  // while the widget tree builds.
  testWidgets('records saved while the visit is covered reach it without '
      'modifying a provider during the build', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sales = StreamController<List<Sale>>.broadcast();
    final payments = StreamController<List<Payment>>.broadcast();
    addTearDown(sales.close);
    addTearDown(payments.close);
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 29, 10)),
          recordSyncStatusProvider((
            entity: PendingEntity.sale,
            id: 'sale-1',
          )).overrideWith((_) => Stream.value(null)),
          routeStopByIdProvider('s-1').overrideWithValue(_stop),
          customerBalanceProvider('c-1').overrideWith((_) => Stream.value(0)),
          stopSalesProvider('s-1').overrideWith((_) async* {
            yield const <Sale>[];
            yield* sales.stream;
          }),
          visitPaymentsProvider('s-1').overrideWith((_) async* {
            yield const <Payment>[];
            yield* payments.stream;
          }),
          visitMovementsProvider('s-1').overrideWith((_) async => []),
          customerContainerBalancesProvider(
            'c-1',
          ).overrideWith((_) => Stream.value([])),
          containerTypesProvider.overrideWith(
            (_) => Stream.value(catalogContainerTypes),
          ),
          visitOutcomesProvider.overrideWith(
            (_) => Stream.value(const [_absent]),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: ThemeData(extensions: [MarilinTokens.light]),
          home: const VisitScreen(stopId: 's-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Agregar otra venta'), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(VisitScreen)),
    );

    unawaited(
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Venta')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Saving a sale reloads the visit's container movements.
    container.invalidate(visitMovementsProvider('s-1'));
    sales.add([_sale]);
    payments.add([
      Payment(
        id: 'pay-1',
        customerId: 'c-1',
        amount: 1900,
        type: PaymentType.cash,
        createdAt: DateTime(2026, 10, 29, 10),
        visitId: 's-1',
        saleId: 'sale-1',
      ),
    ]);
    await tester.pump();

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Agregar otra venta'), findsOneWidget);
  });
}
