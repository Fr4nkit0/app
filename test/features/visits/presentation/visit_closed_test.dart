import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
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
import 'package:app/features/visits/domain/models/visit_summary.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/visits/presentation/screens/visit_screen.dart';

import '../../../support/container_types.dart';

final _customer = Customer(
  id: 'c-1',
  name: 'Tolaba',
  addresses: const [],
  preferences: const [],
);

const _refused = VisitOutcome(
  id: 2,
  code: 'refused',
  name: 'No quiso',
  triggersReschedule: false,
);

const _reschedule = VisitOutcome(
  id: 3,
  code: 'reschedule',
  name: 'Reprogramar',
  triggersReschedule: true,
);

RouteStop _closed(
  VisitSummary visit, {
  StopStatus status = StopStatus.done,
  DateTime? rescheduledToAt,
}) => RouteStop(
  id: 's-1',
  customer: _customer,
  status: status,
  scheduledAt: DateTime(2026, 10, 29, 9),
  rescheduledToAt: rescheduledToAt,
  visit: visit,
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
      quantity: 3,
    ),
  ],
  total: 5700,
  paymentMethod: PaymentMethod.cash,
  date: DateTime(2026, 10, 29, 10),
  visitId: 's-1',
);

Payment _payment({String? saleId, double amount = 2000}) => Payment(
  id: saleId == null ? 'pay-debt' : 'pay-$saleId',
  customerId: 'c-1',
  amount: amount,
  type: PaymentType.cash,
  createdAt: DateTime(2026, 10, 29, 10),
  visitId: 's-1',
  saleId: saleId,
);

ContainerMovement _return(String type, int quantity) => ContainerMovement(
  id: 'mov-$type',
  customerId: 'c-1',
  containerType: type,
  deliveredQuantity: 0,
  returnedQuantity: quantity,
  createdAt: DateTime(2026, 10, 29, 10),
  visitId: 's-1',
);

void main() {
  Future<void> pumpVisit(
    WidgetTester tester,
    RouteStop stop, {
    List<Sale> sales = const [],
    List<Payment> payments = const [],
    List<ContainerMovement> movements = const [],
  }) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordSyncStatusProvider((
            entity: PendingEntity.sale,
            id: 'sale-1',
          )).overrideWith((_) => Stream.value(null)),
          routeStopByIdProvider('s-1').overrideWithValue(stop),
          customerBalanceProvider('c-1').overrideWith((_) => Stream.value(0)),
          stopSalesProvider('s-1').overrideWith((_) => Stream.value(sales)),
          visitPaymentsProvider(
            's-1',
          ).overrideWith((_) => Stream.value(payments)),
          visitMovementsProvider('s-1').overrideWith((_) async => movements),
          customerContainerBalancesProvider(
            'c-1',
          ).overrideWith((_) => Stream.value([])),
          containerTypesProvider.overrideWith(
            (_) => Stream.value(catalogContainerTypes),
          ),
          visitOutcomesProvider.overrideWith(
            (_) => Stream.value(const [_refused, _reschedule]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [MarilinTokens.light]),
          home: const VisitScreen(stopId: 's-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('outcome of a closed visit (S7)', () {
    testWidgets('a sale visit says the sale was registered', (tester) async {
      await pumpVisit(
        tester,
        _closed(
          const VisitSummary(
            salesTotal: 5700,
            saleMethods: [PaymentMethod.cash],
          ),
        ),
        sales: [_sale],
      );

      expect(find.text('Visita con venta'), findsOneWidget);
      expect(find.text('Parada completada con éxito'), findsNothing);
    });

    testWidgets('a visit without sale names its outcome', (tester) async {
      await pumpVisit(tester, _closed(const VisitSummary(outcome: _refused)));

      expect(find.text('Sin venta · No quiso'), findsOneWidget);
      expect(find.text('Visita con venta'), findsNothing);
      expect(find.text('Parada completada con éxito'), findsNothing);
    });
  });

  group('records of a visit (S8)', () {
    testWidgets('a closed visit lists its sales, payments and returns, '
        'without the payments that settle a sale', (tester) async {
      await pumpVisit(
        tester,
        _closed(const VisitSummary(outcome: _refused)),
        sales: [_sale],
        payments: [
          _payment(),
          _payment(saleId: 'sale-1', amount: 5700),
        ],
        movements: [_return('BIDON_20L', 2), _return('SIFON_2L', 1)],
      );

      expect(find.text('REGISTRO'), findsOneWidget);
      expect(find.text('Venta registrada'), findsOneWidget);
      expect(find.text('Cobro registrado'), findsOneWidget);
      expect(find.text('\$2.000'), findsOneWidget);
      expect(find.text('Devolución de envases'), findsOneWidget);
      expect(find.text('2 × Bidón 20L\n1 × Sifón 1.5L'), findsOneWidget);
    });

    testWidgets('an open visit lists a payment made before any sale', (
      tester,
    ) async {
      await pumpVisit(
        tester,
        RouteStop(
          id: 's-1',
          customer: _customer,
          status: StopStatus.pending,
          scheduledAt: DateTime(2026, 10, 29, 9),
        ),
        payments: [_payment()],
      );

      expect(find.text('Cobro registrado'), findsOneWidget);
      // The driver can still choose a sale or a visit without one.
      expect(find.text('ACCIÓN'), findsOneWidget);
    });
  });

  testWidgets('a rescheduled visit shows the new time (S9)', (tester) async {
    await pumpVisit(
      tester,
      _closed(
        const VisitSummary(outcome: _reschedule),
        status: StopStatus.rescheduled,
        rescheduledToAt: DateTime(2026, 10, 29, 16, 30),
      ),
    );

    expect(find.text('Visita reprogramada para las 16:30'), findsOneWidget);
  });
}
