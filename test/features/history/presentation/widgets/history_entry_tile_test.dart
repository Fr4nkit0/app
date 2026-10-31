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

HistoryEntry _issue(
  PendingStatus status, {
  String? reason,
  Map<String, dynamic>? values,
  RejectionRollback? rollback,
  List<String>? fields,
}) => HistoryEntry(
  id: 2,
  type: HistoryEntryType.customer,
  customerId: 'cus-1',
  customerName: 'Ana Gómez',
  date: DateTime(2026, 10, 19, 10, 15),
  description: 'Preferencia agregada',
  status: status,
  rejectionReason: reason,
  rejectedValues: values,
  rollback: rollback,
  changedFields: fields,
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    HistoryEntry entry, {
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HistoryEntryTile(entry: entry, onTap: onTap),
      ),
    ),
  );

  testWidgets('a rejected preference shows its day, window, reason and that '
      'it was undone, and can be opened', (tester) async {
    var taps = 0;
    await pump(
      tester,
      _issue(
        PendingStatus.rejected,
        reason: 'The customer already has a preference for that day and time.',
        values: {
          'day_of_week': 4,
          'time_window_start': '14:00',
          'time_window_end': '16:00',
          'enabled': true,
        },
        rollback: RejectionRollback.deleted,
      ),
      onTap: () => taps++,
    );

    expect(find.text('Jueves 14:00–16:00'), findsOneWidget);
    expect(
      find.text(
        'Motivo: El cliente ya tiene una preferencia para ese día y horario.',
      ),
      findsOneWidget,
    );
    expect(find.text('Se deshizo en el teléfono'), findsOneWidget);

    await tester.tap(find.text('Ana Gómez'));
    expect(taps, 1);
  });

  testWidgets('a rejected customer edit shows the refused fields readably', (
    tester,
  ) async {
    await pump(
      tester,
      _issue(
        PendingStatus.rejected,
        reason: 'invalid',
        values: {
          'phone_number': '111',
          'address.visual_reference': 'Porton AZUL',
        },
        rollback: RejectionRollback.kept,
      ),
    );

    expect(find.text('Teléfono: 111'), findsOneWidget);
    expect(find.text('Referencia: Porton AZUL'), findsOneWidget);
    expect(find.text('Se mantuvo en el teléfono'), findsOneWidget);
  });

  testWidgets('an outdated edit reads as dropped, with its fields', (
    tester,
  ) async {
    await pump(
      tester,
      _issue(
        PendingStatus.outdated,
        fields: ['phone_number', 'address.visual_reference'],
      ),
    );

    expect(find.text('Edición descartada'), findsOneWidget);
    expect(find.text('Descartada'), findsOneWidget);
    expect(find.text('Campos: Teléfono, Referencia'), findsOneWidget);
    expect(find.textContaining('Motivo:'), findsNothing);
  });

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

  testWidgets('shows a known English server reason in Spanish', (tester) async {
    const stored = 'The sale belongs to another driver.';
    final entry = _entry(PendingStatus.rejected, reason: stored);
    await pump(tester, entry);

    expect(find.text('Motivo: Pertenece a otro repartidor.'), findsOneWidget);
    expect(find.text('Motivo: $stored'), findsNothing);
    expect(entry.rejectionReason, stored);
  });

  testWidgets('does not show a reason for records that were not rejected', (
    tester,
  ) async {
    await pump(tester, _entry(PendingStatus.sent));

    expect(find.textContaining('Motivo:'), findsNothing);
  });
}
