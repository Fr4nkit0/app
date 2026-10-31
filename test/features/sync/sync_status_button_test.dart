import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/widgets/sync_status_button.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    SyncStatus status, {
    bool isRunning = false,
    VoidCallback? onPressed,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SyncStatusButton(
          status: status,
          isRunning: isRunning,
          onPressed: onPressed ?? () {},
        ),
      ),
    ),
  );

  testWidgets('shrinks without overflowing when the header is narrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: Row(
              children: [
                Flexible(
                  child: SyncStatusButton(
                    status: SyncStatus(
                      lastCycleAt: DateTime(2026, 10, 21, 10, 53),
                      lastResult: SyncCycleResult.success,
                      pendingCount: 12,
                      rejectedCount: 3,
                    ),
                    isRunning: false,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Sincronizado 10:53'), findsOneWidget);
  });

  testWidgets('shows the last cycle, pending and rejected counts', (
    tester,
  ) async {
    await pump(
      tester,
      SyncStatus(
        lastCycleAt: DateTime(2026, 10, 19, 14, 5),
        lastResult: SyncCycleResult.success,
        pendingCount: 3,
        rejectedCount: 1,
      ),
    );

    expect(find.text('Sincronizado 14:05'), findsOneWidget);
    expect(find.text('3 pendientes'), findsOneWidget);
    expect(find.text('1 rechazado'), findsOneWidget);
  });

  testWidgets('shows a failed cycle and a never-synced state', (tester) async {
    await pump(
      tester,
      SyncStatus(
        lastCycleAt: DateTime(2026, 10, 19, 9, 30),
        lastResult: SyncCycleResult.failure,
        pendingCount: 1,
      ),
    );
    expect(find.text('Falló 09:30'), findsOneWidget);
    expect(find.text('1 pendiente'), findsOneWidget);
    expect(find.text('0 rechazados'), findsOneWidget);

    await pump(tester, const SyncStatus());
    expect(find.text('Sin sincronizar'), findsOneWidget);
  });

  testWidgets('an offline cycle reads as neutral with the saved count', (
    tester,
  ) async {
    await pump(
      tester,
      SyncStatus(
        lastCycleAt: DateTime(2026, 10, 29, 17, 44),
        lastResult: SyncCycleResult.offline,
        pendingCount: 6,
      ),
    );

    expect(find.textContaining('Falló'), findsNothing);
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('6 guardados en el teléfono'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    final headline = tester.widget<Text>(find.text('Sin conexión'));
    expect(headline.style?.color, isNot(MarilinColors.destructive));

    await pump(
      tester,
      SyncStatus(
        lastCycleAt: DateTime(2026, 10, 29, 17, 44),
        lastResult: SyncCycleResult.offline,
        pendingCount: 1,
      ),
    );
    expect(find.text('1 guardado en el teléfono'), findsOneWidget);
  });

  testWidgets('a real failure keeps its red error state', (tester) async {
    await pump(
      tester,
      SyncStatus(
        lastCycleAt: DateTime(2026, 10, 29, 17, 44),
        lastResult: SyncCycleResult.failure,
        pendingCount: 6,
      ),
    );

    final headline = tester.widget<Text>(find.text('Falló 17:44'));
    expect(headline.style?.color, MarilinColors.destructive);
    expect(find.byIcon(Icons.sync_problem), findsOneWidget);
  });

  testWidgets('tapping forces a cycle, except while one is running', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, const SyncStatus(), onPressed: () => taps++);
    await tester.tap(find.byType(SyncStatusButton));
    expect(taps, 1);

    await pump(
      tester,
      const SyncStatus(),
      isRunning: true,
      onPressed: () => taps++,
    );
    expect(find.text('Sincronizando…'), findsOneWidget);
    await tester.tap(find.byType(SyncStatusButton));
    expect(taps, 1);
  });

  testWidgets('tells records held by an open visit apart from pending', (
    tester,
  ) async {
    await pump(
      tester,
      SyncStatus(
        lastCycleAt: DateTime(2026, 10, 21, 10, 53),
        lastResult: SyncCycleResult.success,
        pendingCount: 3,
        heldCount: 2,
      ),
    );

    expect(find.text('1 pendiente'), findsOneWidget);
    expect(find.text('2 esperan cierre de visita'), findsOneWidget);
  });
}
