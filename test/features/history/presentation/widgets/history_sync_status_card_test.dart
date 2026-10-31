import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/history/presentation/widgets/history_sync_status_card.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    SyncStatus status, {
    bool isRunning = false,
    VoidCallback? onSync,
    VoidCallback? onToggleRejected,
    bool showingRejected = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HistorySyncStatusCard(
          status: status,
          isRunning: isRunning,
          onSync: onSync ?? () {},
          onToggleRejected: onToggleRejected,
          showingRejected: showingRejected,
        ),
      ),
    ),
  );

  testWidgets('shows the time, result and counts of the last cycle', (
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

    expect(find.text('Sincronizado a las 14:05'), findsOneWidget);
    expect(find.text('3 pendientes · 1 rechazado'), findsOneWidget);
  });

  testWidgets('shows a failed cycle with its cause', (tester) async {
    await pump(
      tester,
      SyncStatus(
        lastCycleAt: DateTime(2026, 10, 19, 9, 30),
        lastResult: SyncCycleResult.failure,
        lastError: 'Sin conexión',
        pendingCount: 1,
      ),
    );

    expect(find.text('Falló a las 09:30'), findsOneWidget);
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('1 pendiente · 0 rechazados'), findsOneWidget);
  });

  testWidgets('an offline cycle reads as neutral with the saved count', (
    tester,
  ) async {
    await pump(
      tester,
      SyncStatus(
        lastCycleAt: DateTime(2026, 10, 29, 17, 44),
        lastResult: SyncCycleResult.offline,
        pendingCount: 11,
      ),
    );

    expect(find.textContaining('Falló'), findsNothing);
    expect(
      find.text('Sin conexión · 11 guardados en el teléfono'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.cloud_off_rounded));
    expect(icon.color, isNot(MarilinColors.destructive));
  });

  testWidgets('shows when no cycle has run yet', (tester) async {
    await pump(tester, const SyncStatus(pendingCount: 2));

    expect(find.text('Todavía no se sincronizó'), findsOneWidget);
    expect(find.text('2 pendientes · 0 rechazados'), findsOneWidget);
  });

  testWidgets('tapping forces a cycle, except while one is running', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, const SyncStatus(), onSync: () => taps++);
    await tester.tap(find.byType(HistorySyncStatusCard));
    expect(taps, 1);

    await pump(
      tester,
      const SyncStatus(),
      isRunning: true,
      onSync: () => taps++,
    );
    expect(find.text('Sincronizando…'), findsOneWidget);
    await tester.tap(find.byType(HistorySyncStatusCard));
    expect(taps, 1);
  });

  testWidgets('"Ver rechazados" leads to the rejected records instead of '
      'syncing', (tester) async {
    var syncs = 0;
    var toggles = 0;
    await pump(
      tester,
      const SyncStatus(rejectedCount: 1),
      onSync: () => syncs++,
      onToggleRejected: () => toggles++,
    );

    await tester.tap(find.text('Ver rechazados'));
    expect(toggles, 1);
    expect(syncs, 0);

    await pump(
      tester,
      const SyncStatus(rejectedCount: 1),
      showingRejected: true,
      onToggleRejected: () => toggles++,
    );
    expect(find.text('Ver todos'), findsOneWidget);

    await pump(tester, const SyncStatus(), onToggleRejected: () {});
    expect(find.text('Ver rechazados'), findsNothing);
  });

  testWidgets('tells records held by an open visit apart from pending', (
    tester,
  ) async {
    await pump(
      tester,
      SyncStatus(
        lastCycleAt: DateTime(2026, 10, 19, 14, 5),
        lastResult: SyncCycleResult.success,
        pendingCount: 2,
        heldCount: 1,
      ),
    );

    expect(find.text('1 pendiente · 0 rechazados'), findsOneWidget);
    expect(find.text('1 espera cierre de visita'), findsOneWidget);
  });
}
