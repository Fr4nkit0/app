import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/history/presentation/providers/history_list_provider.dart';
import 'package:app/features/history/presentation/providers/paginated_history_provider.dart';
import 'package:app/features/history/presentation/screens/history_screen.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';
import 'package:app/features/sync/sync_engine.dart';

/// Engine whose cycle ends with [result] after [takes]; a lease held by
/// another isolate ends the same way, with the current status.
class _FakeEngine implements SyncEngine {
  _FakeEngine(this.result, {this.takes = const Duration(milliseconds: 300)});

  final SyncCycleResult result;
  final Duration takes;
  int cycles = 0;

  @override
  Future<SyncStatus> runCycle() async {
    cycles++;
    await Future<void>.delayed(takes);
    return SyncStatus(lastResult: result, pendingCount: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _entry = HistoryEntry(
  id: 1,
  type: HistoryEntryType.sale,
  customerId: 'cus-1',
  customerName: 'Ana Gómez',
  date: DateTime(2026, 10, 19, 10, 15),
  amount: 4500,
  description: 'Venta',
  status: PendingStatus.pending,
);

void main() {
  Future<_FakeEngine> pumpHistory(
    WidgetTester tester,
    SyncCycleResult result, {
    Duration takes = const Duration(milliseconds: 300),
  }) async {
    final engine = _FakeEngine(result, takes: takes);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyListProvider.overrideWith((ref) => Stream.value([_entry])),
          syncStatusProvider.overrideWith(
            (ref) => Stream.value(const SyncStatus()),
          ),
          syncRunningProvider.overrideWith((ref) => Stream.value(false)),
          syncEngineProvider.overrideWithValue(engine),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return engine;
  }

  final cases = {
    for (final r in SyncCycleResult.values)
      'a ${r.name} cycle': (r, const Duration(milliseconds: 300)),
    // A lease held elsewhere returns the current status at once.
    'a busy lease': (SyncCycleResult.offline, Duration.zero),
  };
  for (final MapEntry(key: name, value: (result, takes)) in cases.entries) {
    testWidgets('pull-to-refresh ends after $name', (tester) async {
      final engine = await pumpHistory(tester, result, takes: takes);
      expect(find.text('Ana Gómez'), findsOneWidget);

      await tester.fling(find.text('Ana Gómez'), const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(engine.cycles, 1);
      // The indicator finishes its hide animation.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(RefreshProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Ana Gómez'), findsOneWidget);
    });
  }

  test('the list is back when Historial is opened again', () async {
    final container = ProviderContainer(
      overrides: [
        historyListProvider.overrideWith((ref) => Stream.value([_entry])),
      ],
    );
    addTearDown(container.dispose);
    final first = container.listen(paginatedHistoryProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    first.close();
    await Future<void>.delayed(Duration.zero);

    final state = container.listen(paginatedHistoryProvider, (_, _) {}).read();

    expect(state.isLoading, isFalse);
    expect(state.entries, [_entry]);
  });
}
