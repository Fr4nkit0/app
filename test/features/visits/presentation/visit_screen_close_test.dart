import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';
import 'package:app/features/visits/domain/usecases/complete_visit.usecase.dart';
import 'package:app/features/visits/presentation/providers/complete_visit_usecase_provider.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/visits/presentation/screens/visit_screen.dart';

class _FakeCompleteVisit implements CompleteVisitUseCase {
  final completer = Completer<Resource<void>>();
  int calls = 0;
  DateTime? lastRescheduleAt;

  @override
  Future<Resource<void>> execute({
    required String stopId,
    required String customerId,
    required VisitType visitType,
    required StopStatus nextStatus,
    int? outcomeId,
    String? observations,
    DateTime? rescheduleAt,
  }) {
    calls++;
    lastRescheduleAt = rescheduleAt;
    return completer.future;
  }
}

const _name = 'Kiosco Norte';
const _absent = VisitOutcome(
  id: 1,
  code: 'absent',
  name: 'Ausente',
  triggersReschedule: false,
);
const _reschedule = VisitOutcome(
  id: 2,
  code: 'reschedule',
  name: 'Reprogramar',
  triggersReschedule: true,
);

final _stop = RouteStop(
  id: 's-1',
  customer: Customer(
    id: 'c-1',
    name: _name,
    addresses: const [],
    preferences: const [],
  ),
  status: StopStatus.pending,
  scheduledAt: DateTime(2026, 10, 28, 9),
);

final _sale = Sale(
  id: 'sale-1',
  customer: _stop.customer,
  items: const [
    SaleItem(
      product: Product(id: 'p-1', name: 'Soda', unitLabel: 'u', price: 100),
      quantity: 1,
    ),
  ],
  total: 100,
  paymentMethod: PaymentMethod.cash,
  date: DateTime(2026, 10, 28),
  visitId: 's-1',
);

Future<_FakeCompleteVisit> _pumpVisit(
  WidgetTester tester, {
  List<Sale> sales = const [],
}) async {
  final fake = _FakeCompleteVisit();
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        completeVisitUseCaseProvider.overrideWithValue(fake),
        routeStopByIdProvider('s-1').overrideWithValue(_stop),
        customerBalanceProvider('c-1').overrideWith((_) => Stream.value(0.0)),
        stopSalesProvider('s-1').overrideWith((_) => Stream.value(sales)),
        visitPaymentsProvider('s-1').overrideWith((_) => Stream.value([])),
        visitMovementsProvider('s-1').overrideWith((_) async => []),
        visitOutcomesProvider.overrideWith(
          (_) => Stream.value(const [_absent, _reschedule]),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [MarilinTokens.light]),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VisitScreen(stopId: 's-1'),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return fake;
}

Finder get _primary => find.widgetWithText(FilledButton, 'Cerrar visita');

Future<void> _selectAbsent(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Ausente'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ausente'));
  await tester.pump();
}

void main() {
  testWidgets('a second tap while closing runs the use case once and shows '
      'a spinner in the footer', (tester) async {
    final fake = await _pumpVisit(tester);
    await _selectAbsent(tester);

    await tester.tap(_primary);
    await tester.pump();
    await tester.tap(_primary, warnIfMissed: false);
    await tester.pump();

    expect(fake.calls, 1);
    expect(
      find.descendant(
        of: _primary,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(_primary).onPressed, isNull);
    expect(find.byType(VisitScreen), findsOneWidget);

    fake.completer.complete(const Resource.success(null));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('a failed close stays on screen, re-enables the footer and '
      'hides the raw error', (tester) async {
    final fake = await _pumpVisit(tester);
    await _selectAbsent(tester);

    await tester.tap(_primary);
    await tester.pump();
    fake.completer.complete(Resource.error(Exception('boom')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(VisitScreen), findsOneWidget);
    expect(find.text('No se guardó la visita. Reintentá.'), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
    expect(tester.widget<FilledButton>(_primary).onPressed, isNotNull);
    expect(
      find.descendant(
        of: _primary,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a plain visit pops and recaps with the customer name', (
    tester,
  ) async {
    final fake = await _pumpVisit(tester);
    await _selectAbsent(tester);

    await tester.tap(_primary);
    await tester.pump();
    fake.completer.complete(const Resource.success(null));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(VisitScreen), findsNothing);
    expect(find.text('Visita cerrada · $_name'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a visit with sales recaps "Venta registrada"', (tester) async {
    final fake = await _pumpVisit(tester, sales: [_sale]);

    await tester.tap(_primary);
    await tester.pump();
    fake.completer.complete(const Resource.success(null));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(VisitScreen), findsNothing);
    expect(find.text('Venta registrada · $_name'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a rescheduled visit recaps the chosen time', (tester) async {
    final fake = await _pumpVisit(tester);
    await tester.ensureVisible(find.text('Reprogramar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reprogramar'));
    await tester.pump();
    await tester.ensureVisible(find.text('Elegir hora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir hora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final label = find.textContaining('Hoy, ');
    final time = tester.widget<Text>(label).data!.replaceFirst('Hoy, ', '');

    await tester.tap(_primary);
    await tester.pump();
    fake.completer.complete(const Resource.success(null));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(fake.lastRescheduleAt, isNotNull);
    expect(find.byType(VisitScreen), findsNothing);
    expect(find.text('Reprogramada $time · $_name'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
  });
}
