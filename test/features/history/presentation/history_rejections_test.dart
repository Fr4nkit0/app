import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/history/presentation/providers/history_list_provider.dart';
import 'package:app/features/history/presentation/screens/history_screen.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/providers/pending_change_repository_provider.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';

HistoryEntry _entry(
  int id,
  String name,
  PendingStatus status, {
  Map<String, dynamic>? values,
}) => HistoryEntry(
  id: id,
  type: HistoryEntryType.customer,
  customerId: 'cus-$id',
  customerName: name,
  date: DateTime(2026, 10, 19, 10, id),
  description: 'Preferencia agregada',
  status: status,
  rejectionReason: status == PendingStatus.rejected
      ? 'The customer already has a preference for that day and time.'
      : null,
  rejectedValues: values,
  rollback: values == null ? null : RejectionRollback.deleted,
);

/// Queue that dismisses by marking the entry, as the database does.
class _FakeQueue implements PendingChangeRepository {
  _FakeQueue(this.entries);

  List<HistoryEntry> entries;
  final controller = StreamController<List<HistoryEntry>>.broadcast();
  final dismissed = <int>[];

  @override
  Future<void> dismiss(int id) async {
    dismissed.add(id);
    entries = [
      for (final e in entries)
        e.id == id ? _entry(e.id, e.customerName, PendingStatus.dismissed) : e,
    ];
    controller.add(entries);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<_FakeQueue> pumpHistory(WidgetTester tester) async {
    // Tall enough to build every record of the list.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final queue = _FakeQueue([
      _entry(
        3,
        'Kiosco Norte',
        PendingStatus.rejected,
        values: {
          'day_of_week': 4,
          'time_window_start': '14:00',
          'time_window_end': '16:00',
        },
      ),
      _entry(2, 'Ana Gómez', PendingStatus.sent),
      _entry(1, 'Bar Sur', PendingStatus.dismissed),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyListProvider.overrideWith((ref) async* {
            yield queue.entries;
            yield* queue.controller.stream;
          }),
          pendingChangeRepositoryProvider.overrideWithValue(queue),
          syncStatusProvider.overrideWith(
            (ref) => Stream.value(const SyncStatus(rejectedCount: 1)),
          ),
          syncRunningProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HistoryScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return queue;
  }

  testWidgets('a dismissed record is not listed', (tester) async {
    await pumpHistory(tester);

    expect(find.text('Kiosco Norte'), findsOneWidget);
    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('Bar Sur'), findsNothing);
  });

  testWidgets('a rejected record opens its detail and "Descartar" dismisses '
      'it', (tester) async {
    final queue = await pumpHistory(tester);

    await tester.tap(find.text('Kiosco Norte'));
    await tester.pumpAndSettle();

    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Cambio rechazado')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Jueves 14:00–16:00')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.text(
          'Motivo: El cliente ya tiene una preferencia para ese día y horario.',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Descartar'));
    await tester.pumpAndSettle();

    expect(queue.dismissed, [3]);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Kiosco Norte'), findsNothing);
    expect(find.text('Ana Gómez'), findsOneWidget);
  });

  testWidgets('"Ver rechazados" lists only the rejected records', (
    tester,
  ) async {
    await pumpHistory(tester);

    await tester.tap(find.text('Ver rechazados'));
    await tester.pump();

    expect(find.text('Kiosco Norte'), findsOneWidget);
    expect(find.text('Ana Gómez'), findsNothing);

    await tester.tap(find.text('Ver todos'));
    await tester.pump();

    expect(find.text('Ana Gómez'), findsOneWidget);
  });
}
