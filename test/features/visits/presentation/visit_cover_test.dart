import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/visits/presentation/screens/visit_screen.dart';

import '../../../support/container_types.dart';
import '../../../support/real_fonts.dart';

const _refused = VisitOutcome(
  id: 2,
  code: 'refused',
  name: 'No quiso',
  triggersReschedule: false,
);

const _longDriver =
    'Juan Sebastián Fernández de la Cruz Rodríguez Villanueva Montenegro';

RouteStop _stop({bool isCover = false, String? coveredDriverName}) => RouteStop(
  id: 's-1',
  customer: Customer(
    id: 'c-1',
    name: 'Tolaba',
    addresses: const [],
    preferences: const [],
  ),
  status: StopStatus.pending,
  scheduledAt: DateTime(2026, 10, 30, 9),
  isCover: isCover,
  coveredDriverName: coveredDriverName,
);

void main() {
  setUpAll(() async {
    expect(
      await loadRealFonts(),
      isTrue,
      reason: 'Roboto was not found in the Flutter SDK cache',
    );
  });

  Future<void> pumpVisit(WidgetTester tester, RouteStop stop) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routeStopByIdProvider('s-1').overrideWithValue(stop),
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
            (_) => Stream.value(const [_refused]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const VisitScreen(stopId: 's-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a covered visit names the owner driver in the header', (
    tester,
  ) async {
    await pumpVisit(tester, _stop(isCover: true, coveredDriverName: 'Pedro'));

    expect(find.text('Cubriendo a Pedro'), findsOneWidget);
  });

  testWidgets('an own visit shows no cover label', (tester) async {
    await pumpVisit(tester, _stop());

    expect(find.textContaining('Cubriendo a'), findsNothing);
  });

  testWidgets('a covered visit without an owner name shows no label', (
    tester,
  ) async {
    await pumpVisit(tester, _stop(isCover: true));

    expect(find.textContaining('Cubriendo a'), findsNothing);
  });

  testWidgets('a long owner name ends in an ellipsis without overflow at '
      '360dp', (tester) async {
    await pumpVisit(
      tester,
      _stop(isCover: true, coveredDriverName: _longDriver),
    );

    final label = tester.widget<Text>(find.text('Cubriendo a $_longDriver'));
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
