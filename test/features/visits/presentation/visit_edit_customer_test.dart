import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/providers/clock_provider.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/domain/models/visit_summary.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/visits/presentation/screens/visit_screen.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/screens/edit_customer_screen.dart';
import 'package:app/features/balance_corrections/presentation/widgets/balance_correction_sheet.dart';

import '../../../support/container_types.dart';

const _absent = VisitOutcome(
  id: 1,
  code: 'absent',
  name: 'Ausente',
  triggersReschedule: false,
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

final _now = DateTime(2026, 10, 29, 12);

RouteStop _stop({
  VisitOutcome? outcome = _refused,
  DateTime? arrivedAt,
  List<PaymentMethod> saleMethods = const [],
  StopStatus status = StopStatus.done,
}) => RouteStop(
  id: 's-1',
  customer: Customer(
    id: 'c-1',
    name: 'Tolaba',
    addresses: const [],
    preferences: const [],
  ),
  status: status,
  scheduledAt: DateTime(2026, 10, 29, 9),
  visit: VisitSummary(
    visitId: 'v-1',
    arrivedAt: arrivedAt ?? DateTime(2026, 10, 29, 10),
    outcome: outcome,
    notes: 'Tocar timbre',
    saleMethods: saleMethods,
  ),
);

void main() {
  Future<void> pumpVisit(
    WidgetTester tester, {
    StopStatus status = StopStatus.pending,
  }) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final stop = _stop(outcome: null, status: status);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => _now),
          routeStopByIdProvider('s-1').overrideWith((ref) => stop),
          customerByIdProvider(
            'c-1',
          ).overrideWith((_) => Stream.value(stop.customer)),
          customerBalanceProvider('c-1').overrideWith((_) => Stream.value(0)),
          stopSalesProvider('s-1').overrideWith((_) => Stream.value([])),
          visitPaymentsProvider('s-1').overrideWith((_) => Stream.value([])),
          visitMovementsProvider('s-1').overrideWith((_) async => []),
          customerContainerBalancesProvider(
            'c-1',
          ).overrideWith((_) => Stream.value([])),
          containerTypesProvider.overrideWith(
            (_) => Stream.value(catalogContainerTypes),
          ),
          visitOutcomesProvider.overrideWith(
            (_) => Stream.value(const [_absent, _refused, _reschedule]),
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

  final editCustomer = find.byTooltip('Editar cliente');

  testWidgets('the customer card opens the edit of this customer and goes '
      'back to the visit', (tester) async {
    await pumpVisit(tester);

    expect(editCustomer, findsOneWidget);
    await tester.tap(editCustomer);
    await tester.pumpAndSettle();

    final edit = tester.widget<EditCustomerScreen>(
      find.byType(EditCustomerScreen),
    );
    expect(edit.customer.id, 'c-1');

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.byType(EditCustomerScreen), findsNothing);
    expect(find.byType(VisitScreen), findsOneWidget);
    expect(find.text('CLIENTE ACTUAL'), findsOneWidget);
  });

  final correctBalance = find.text('Corregir saldo');

  testWidgets('a visit in progress opens the balance correction sheet', (
    tester,
  ) async {
    await pumpVisit(tester);

    expect(correctBalance, findsOneWidget);
    await tester.tap(correctBalance);
    await tester.pumpAndSettle();

    expect(find.byType(BalanceCorrectionSheet), findsOneWidget);
    expect(find.byType(VisitScreen), findsOneWidget);
  });

  testWidgets('a closed visit does not offer the balance correction', (
    tester,
  ) async {
    await pumpVisit(tester, status: StopStatus.done);

    expect(correctBalance, findsNothing);
  });
}
