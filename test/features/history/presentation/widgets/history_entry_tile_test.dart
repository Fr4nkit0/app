import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/history/presentation/widgets/history_entry_tile.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

HistoryEntry _entry(PendingStatus status, {String? reason}) => HistoryEntry(
  id: 1,
  type: HistoryEntryType.sale,
  customerId: 'cus-1',
  customerName: 'Ana Gómez',
  date: DateTime(2026, 10, 19, 10, 15),
  amount: 4500,
  description: 'Venta',
  status: status,
  rejectionReason: reason,
);

void main() {
  Future<void> pump(WidgetTester tester, HistoryEntry entry) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: HistoryEntryTile(entry: entry)),
        ),
      );

  testWidgets('shows a pending record as unsent', (tester) async {
    await pump(tester, _entry(PendingStatus.pending));

    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('Sin enviar'), findsOneWidget);
    expect(find.text('Pendiente'), findsNothing);
    expect(find.text('Enviado'), findsNothing);
    expect(find.text('Rechazado'), findsNothing);
  });

  testWidgets('shows no pill for a sent record', (tester) async {
    await pump(tester, _entry(PendingStatus.sent));

    expect(find.text('Enviado'), findsNothing);
    expect(find.text('Sin enviar'), findsNothing);
    expect(find.text('Rechazado'), findsNothing);
  });

  testWidgets('shows a rejected record with its reason', (tester) async {
    await pump(
      tester,
      _entry(PendingStatus.rejected, reason: 'Cliente dado de baja'),
    );

    expect(find.text('Rechazado'), findsOneWidget);
    expect(find.text('Motivo: Cliente dado de baja'), findsOneWidget);
  });

  testWidgets('does not show a reason for records that were not rejected', (
    tester,
  ) async {
    await pump(tester, _entry(PendingStatus.sent));

    expect(find.textContaining('Motivo:'), findsNothing);
  });
}
