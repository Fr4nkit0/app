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
import 'package:app/features/visits/domain/usecases/edit_visit.usecase.dart';
import 'package:app/features/visits/presentation/providers/edit_visit_usecase_provider.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/visits/presentation/screens/visit_screen.dart';

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

/// The stop the screen shows; the fake edit replaces it like the database
/// would.
class _StopHolder extends Notifier<RouteStop> {
  _StopHolder(this._initial);

  final RouteStop _initial;

  @override
  RouteStop build() => _initial;

  void set(RouteStop stop) => state = stop;
}

class _FakeEditVisit implements EditVisitUseCase {
  void Function(int outcomeId, String? notes) onEdit = (_, _) {};
  final calls = <(String, int, String?)>[];

  @override
  Future<void> execute({
    required String visitId,
    required int outcomeId,
    String? notes,
  }) async {
    calls.add((visitId, outcomeId, notes));
    onEdit(outcomeId, notes);
  }
}

void main() {
  Future<_FakeEditVisit> pumpVisit(WidgetTester tester, RouteStop stop) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final holder = NotifierProvider<_StopHolder, RouteStop>(
      () => _StopHolder(stop),
    );
    final fake = _FakeEditVisit();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => _now),
          routeStopByIdProvider('s-1').overrideWith((ref) => ref.watch(holder)),
          editVisitUseCaseProvider.overrideWith((ref) {
            fake.onEdit = (outcomeId, notes) {
              final edited = [
                _absent,
                _refused,
              ].firstWhere((o) => o.id == outcomeId);
              ref.read(holder.notifier).set(_stop(outcome: edited));
            };
            return fake;
          }),
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
    return fake;
  }

  final editAction = find.text('Editar resultado');

  testWidgets('a closed visit of today without a sale offers the edit', (
    tester,
  ) async {
    await pumpVisit(tester, _stop());

    expect(editAction, findsOneWidget);
  });

  testWidgets('a visit with a sale does not offer the edit', (tester) async {
    await pumpVisit(
      tester,
      _stop(outcome: null, saleMethods: [PaymentMethod.cash]),
    );

    expect(editAction, findsNothing);
  });

  testWidgets('a visit of another day does not offer the edit', (tester) async {
    await pumpVisit(tester, _stop(arrivedAt: DateTime(2026, 10, 28, 18)));

    expect(editAction, findsNothing);
  });

  testWidgets('a rescheduled visit does not offer the edit', (tester) async {
    await pumpVisit(
      tester,
      _stop(outcome: _reschedule, status: StopStatus.rescheduled),
    );

    expect(editAction, findsNothing);
  });

  testWidgets('saving the edit sends the new outcome and notes and updates '
      'the banner', (tester) async {
    final fake = await pumpVisit(tester, _stop());
    expect(find.text('Sin venta · No quiso'), findsOneWidget);

    await tester.tap(editAction);
    await tester.pumpAndSettle();

    expect(find.text('Guardar'), findsOneWidget);
    // Rescheduling creates a stop, so it is not an edit.
    expect(find.widgetWithText(ChoiceChip, 'Reprogramar'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Ausente'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Tocar timbre'),
      'No estaba',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(fake.calls, [('v-1', 1, 'No estaba')]);
    expect(find.text('Sin venta · Ausente'), findsOneWidget);
  });
}
