import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/widgets/next_stop_card.dart';
import 'package:app/features/route/presentation/widgets/route_stop_card.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/providers/pending_change_repository_provider.dart';

import '../../../support/real_fonts.dart';

const _longDriver =
    'Juan Sebastián Fernández de la Cruz Rodríguez Villanueva Montenegro';

RouteStop _stop({
  StopStatus status = StopStatus.pending,
  bool isCover = false,
  String? coveredDriverName,
}) => RouteStop(
  id: 's-1',
  customer: Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  ),
  status: status,
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

  Future<void> pump(WidgetTester tester, RouteStop stop, {Widget? card}) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recordSyncStatusProvider((
            entity: PendingEntity.routeStop,
            id: 's-1',
          )).overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: card ?? RouteStopCard(stop: stop, onTap: () {}),
            ),
          ),
        ),
      ),
    );
  }

  for (final status in [StopStatus.pending, StopStatus.done]) {
    testWidgets('a covered ${status.name} stop names its owner driver', (
      tester,
    ) async {
      await pump(
        tester,
        _stop(status: status, isCover: true, coveredDriverName: 'Pedro'),
      );

      expect(find.text('Cubriendo a Pedro'), findsOneWidget);
    });
  }

  testWidgets('an own stop shows no cover label', (tester) async {
    await pump(tester, _stop());

    expect(find.textContaining('Cubriendo a'), findsNothing);
  });

  for (final name in [null, '', '   ']) {
    testWidgets('a covered stop without an owner name ("$name") shows no '
        'label', (tester) async {
      await pump(tester, _stop(isCover: true, coveredDriverName: name));

      expect(find.textContaining('Cubriendo a'), findsNothing);
    });
  }

  testWidgets('a long owner name ends in an ellipsis without overflow at '
      '360dp', (tester) async {
    await pump(tester, _stop(isCover: true, coveredDriverName: _longDriver));

    final label = tester.widget<Text>(find.text('Cubriendo a $_longDriver'));
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the next-stop hero names the owner driver of a covered stop', (
    tester,
  ) async {
    final stop = _stop(isCover: true, coveredDriverName: 'Pedro');
    await pump(
      tester,
      stop,
      card: NextStopCard(stop: stop, custodyCount: 0, onTap: () {}),
    );

    expect(find.text('Cubriendo a Pedro'), findsOneWidget);
  });
}
