import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/providers/clock_provider.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/usecases/cancel_payment.usecase.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/cancel_sale.usecase.dart';
import 'package:app/features/sales/presentation/providers/cancel_sale_usecase_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/visits/domain/models/visit_summary.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/visits/presentation/screens/visit_screen.dart';

import '../../../support/container_types.dart';

final _now = DateTime(2026, 10, 29, 12);
final _customer = Customer(
  id: 'c-1',
  name: 'Tolaba',
  addresses: const [],
  preferences: const [],
);

final _stop = RouteStop(
  id: 's-1',
  customer: _customer,
  status: StopStatus.done,
  scheduledAt: DateTime(2026, 10, 29, 9),
  visit: VisitSummary(
    visitId: 'v-1',
    arrivedAt: DateTime(2026, 10, 29, 10),
    saleMethods: const [PaymentMethod.cash],
    salesTotal: 2400,
  ),
);

Sale _sale({DateTime? date, bool cancelled = false}) => Sale(
  id: 'sale-1',
  customer: _customer,
  items: const [
    SaleItem(
      product: Product(id: 'p-1', name: 'Agua 20L', unitLabel: '', price: 1200),
      quantity: 2,
    ),
  ],
  total: 2400,
  paymentMethod: PaymentMethod.cash,
  date: date ?? DateTime(2026, 10, 29, 10),
  visitId: 's-1',
  isCancelled: cancelled,
);

ContainerMovement _return({String id = 'mov-1', String? saleId}) =>
    ContainerMovement(
      id: id,
      customerId: 'c-1',
      containerType: 'BIDON_20L',
      deliveredQuantity: 0,
      returnedQuantity: 2,
      createdAt: DateTime(2026, 10, 29, 10),
      visitId: 's-1',
      saleId: saleId,
    );

Payment _payment({
  String id = 'pay-debt',
  String? saleId,
  DateTime? at,
  bool cancelled = false,
}) => Payment(
  id: id,
  customerId: 'c-1',
  amount: 500,
  type: PaymentType.cash,
  createdAt: at ?? DateTime(2026, 10, 29, 10, 30),
  visitId: 's-1',
  saleId: saleId,
  isCancelled: cancelled,
);

/// The records the screen shows; the fake cancellations change them like
/// the database would.
class _Records extends Notifier<(List<Sale>, List<Payment>)> {
  _Records(this._initial);

  final (List<Sale>, List<Payment>) _initial;

  @override
  (List<Sale>, List<Payment>) build() => _initial;

  void set(List<Sale> sales, List<Payment> payments) =>
      state = (sales, payments);
}

class _FakeCancelSale implements CancelSaleUseCase {
  void Function() onCancel = () {};
  final calls = <(String, String?)>[];

  @override
  Future<void> execute(String saleId, {String? reason}) async {
    calls.add((saleId, reason));
    onCancel();
  }
}

class _FakeCancelPayment implements CancelPaymentUseCase {
  final calls = <(String, String?)>[];

  @override
  Future<void> execute(String paymentId, {String? reason}) async {
    calls.add((paymentId, reason));
  }
}

void main() {
  late _FakeCancelSale cancelSale;
  late _FakeCancelPayment cancelPayment;

  Future<void> pumpVisit(
    WidgetTester tester, {
    required List<Sale> sales,
    List<Payment> payments = const [],
    List<ContainerMovement> movements = const [],
  }) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final records = NotifierProvider<_Records, (List<Sale>, List<Payment>)>(
      () => _Records((sales, payments)),
    );
    cancelSale = _FakeCancelSale();
    cancelPayment = _FakeCancelPayment();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => _now),
          routeStopByIdProvider('s-1').overrideWith((ref) => _stop),
          cancelSaleUseCaseProvider.overrideWith((ref) {
            cancelSale.onCancel = () {
              final (current, paid) = ref.read(records);
              ref.read(records.notifier).set([
                for (final s in current) _sale(date: s.date, cancelled: true),
              ], paid);
            };
            return cancelSale;
          }),
          cancelPaymentUseCaseProvider.overrideWithValue(cancelPayment),
          customerBalanceProvider('c-1').overrideWith((_) => Stream.value(0)),
          stopSalesProvider(
            's-1',
          ).overrideWith((ref) => Stream.value(ref.watch(records).$1)),
          visitPaymentsProvider(
            's-1',
          ).overrideWith((ref) => Stream.value(ref.watch(records).$2)),
          visitMovementsProvider('s-1').overrideWith((_) async => movements),
          customerContainerBalancesProvider(
            'c-1',
          ).overrideWith((_) => Stream.value([])),
          containerTypesProvider.overrideWith(
            (_) => Stream.value(catalogContainerTypes),
          ),
          visitOutcomesProvider.overrideWith((_) => Stream.value(const [])),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [MarilinTokens.light]),
          home: const VisitScreen(stopId: 's-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final cancelSaleAction = find.text('Anular venta');
  final cancelPaymentAction = find.text('Anular cobro');

  testWidgets('a confirmed sale of today offers its cancellation and a debt '
      'payment offers its own', (tester) async {
    await pumpVisit(
      tester,
      sales: [_sale()],
      payments: [
        _payment(),
        _payment(id: 'pay-sale', saleId: 'sale-1'),
      ],
    );

    expect(cancelSaleAction, findsOneWidget);
    // The payment that settled the sale is part of the sale's card.
    expect(cancelPaymentAction, findsOneWidget);
  });

  testWidgets('records of another day offer no cancellation', (tester) async {
    await pumpVisit(
      tester,
      sales: [_sale(date: DateTime(2026, 10, 28, 18))],
      payments: [_payment(at: DateTime(2026, 10, 28, 18))],
    );

    expect(cancelSaleAction, findsNothing);
    expect(cancelPaymentAction, findsNothing);
  });

  testWidgets('cancelled records show as cancelled and offer nothing', (
    tester,
  ) async {
    await pumpVisit(
      tester,
      sales: [_sale(cancelled: true)],
      payments: [_payment(cancelled: true)],
    );

    expect(find.text('Venta anulada'), findsOneWidget);
    expect(find.text('Venta registrada'), findsNothing);
    expect(find.text('Anulada'), findsOneWidget);
    expect(find.text('Anulado'), findsOneWidget);
    expect(cancelSaleAction, findsNothing);
    expect(cancelPaymentAction, findsNothing);
  });

  testWidgets('cancelling a sale asks first, warns that its payments are '
      'cancelled too and sends the reason', (tester) async {
    await pumpVisit(tester, sales: [_sale()]);

    await tester.tap(cancelSaleAction);
    await tester.pumpAndSettle();

    expect(find.text('¿Anular la venta?'), findsOneWidget);
    expect(find.textContaining('cobros de esta venta'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Motivo (opcional)'),
      'Devolvió el bidón',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Anular'));
    await tester.pumpAndSettle();

    expect(cancelSale.calls, [('sale-1', 'Devolvió el bidón')]);
    expect(find.text('Venta anulada'), findsWidgets);
    expect(find.text('Venta registrada'), findsNothing);
    expect(find.text('Anulada'), findsOneWidget);
    expect(cancelSaleAction, findsNothing);
  });

  testWidgets('a confirmed sale keeps the "Venta registrada" header', (
    tester,
  ) async {
    await pumpVisit(tester, sales: [_sale()]);

    expect(find.text('Venta registrada'), findsOneWidget);
    expect(find.text('Venta anulada'), findsNothing);
  });

  testWidgets('backing out of the dialog cancels nothing', (tester) async {
    await pumpVisit(tester, sales: [_sale()]);

    await tester.tap(cancelSaleAction);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Volver'));
    await tester.pumpAndSettle();

    expect(cancelSale.calls, isEmpty);
    expect(cancelSaleAction, findsOneWidget);
  });

  testWidgets('cancelling a debt payment asks first and sends no empty '
      'reason', (tester) async {
    await pumpVisit(tester, sales: const [], payments: [_payment()]);

    await tester.tap(cancelPaymentAction);
    await tester.pumpAndSettle();

    expect(find.text('¿Anular el cobro?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Anular'));
    await tester.pumpAndSettle();

    expect(cancelPayment.calls, [('pay-debt', null)]);
  });

  final returnTitle = find.text('Devolución de envases');

  testWidgets('the container return of a cancelled sale shows as cancelled', (
    tester,
  ) async {
    await pumpVisit(
      tester,
      sales: [_sale(cancelled: true)],
      movements: [_return(saleId: 'sale-1')],
    );

    expect(returnTitle, findsOneWidget);
    // The sale's badge and the return's badge.
    expect(find.text('Anulada'), findsNWidgets(2));
    expect(
      tester.widget<Text>(find.text('2 × Bidón 20L')).style?.decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('cancelling the sale marks its container return as cancelled', (
    tester,
  ) async {
    await pumpVisit(
      tester,
      sales: [_sale()],
      movements: [_return(saleId: 'sale-1')],
    );
    expect(find.text('Anulada'), findsNothing);

    await tester.tap(cancelSaleAction);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Anular'));
    await tester.pumpAndSettle();

    expect(find.text('Anulada'), findsNWidgets(2));
  });

  testWidgets('a return without a sale stays a valid return next to a '
      'cancelled sale', (tester) async {
    await pumpVisit(
      tester,
      sales: [_sale(cancelled: true)],
      movements: [
        _return(saleId: 'sale-1'),
        _return(id: 'mov-2'),
      ],
    );

    expect(returnTitle, findsNWidgets(2));
    expect(find.text('Anulada'), findsNWidgets(2));
    expect(
      tester
          .widgetList<Text>(find.text('2 × Bidón 20L'))
          .map((text) => text.style?.decoration),
      containsAll([
        TextDecoration.lineThrough,
        isNot(TextDecoration.lineThrough),
      ]),
    );
  });
}
