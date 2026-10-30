import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/widgets/sync_badge.dart';

PendingChange _change(PendingStatus status, {String? reason}) => PendingChange(
  id: 1,
  entity: PendingEntity.sale,
  entityId: 'sale-1',
  action: PendingAction.insert,
  status: status,
  rejectionReason: reason,
  createdAt: DateTime(2026, 10, 28),
);

void main() {
  Future<void> pump(WidgetTester tester, PendingChange? change) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: SyncBadge(change: change)),
          ),
        ),
      );

  testWidgets('renders nothing for null', (tester) async {
    await pump(tester, null);

    expect(find.byType(Text), findsNothing);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('renders nothing for a sent change', (tester) async {
    await pump(tester, _change(PendingStatus.sent));

    expect(find.byType(Text), findsNothing);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('pending shows "Sin enviar" with the brand style', (
    tester,
  ) async {
    await pump(tester, _change(PendingStatus.pending));

    expect(find.text('Sin enviar'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.cloud_upload_outlined));
    expect(icon.size, 14);
    final text = tester.widget<Text>(find.text('Sin enviar'));
    expect(text.style?.fontSize, 13);
    expect(text.style?.fontWeight, FontWeight.w700);
    expect(text.style?.color, MarilinColors.brandBlue);
  });

  testWidgets('pending is not tappable and exposes a non-button label', (
    tester,
  ) async {
    await pump(tester, _change(PendingStatus.pending));

    expect(find.byType(InkWell), findsNothing);
    await tester.tap(find.text('Sin enviar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Sin enviar')),
      isSemantics(label: 'Sin enviar', isButton: false),
    );
  });

  testWidgets('rejected shows "Rechazado" with a 44dp hit area', (
    tester,
  ) async {
    await pump(tester, _change(PendingStatus.rejected, reason: 'Motivo X'));

    expect(find.text('Rechazado'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    final text = tester.widget<Text>(find.text('Rechazado'));
    expect(text.style?.color, MarilinColors.destructive);
    final size = tester.getSize(find.byType(InkWell));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Rechazado')),
      isSemantics(label: 'Rechazado', isButton: true, hasTapAction: true),
    );
  });

  testWidgets('tapping rejected opens the dialog with the server reason', (
    tester,
  ) async {
    await pump(
      tester,
      _change(PendingStatus.rejected, reason: 'Cliente dado de baja'),
    );

    await tester.tap(find.text('Rechazado'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('El servidor rechazó este cambio'), findsOneWidget);
    expect(find.text('Cliente dado de baja'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a known English server reason is shown in Spanish', (
    tester,
  ) async {
    const stored = "Only today's records can be cancelled.";
    final change = _change(PendingStatus.rejected, reason: stored);
    await pump(tester, change);

    await tester.tap(find.text('Rechazado'));
    await tester.pumpAndSettle();

    expect(
      find.text('Solo se pueden anular registros del día.'),
      findsOneWidget,
    );
    expect(find.text(stored), findsNothing);
    expect(change.rejectionReason, stored);
  });

  testWidgets('an empty reason falls back to "Sin motivo informado."', (
    tester,
  ) async {
    await pump(tester, _change(PendingStatus.rejected, reason: '  '));

    await tester.tap(find.text('Rechazado'));
    await tester.pumpAndSettle();

    expect(find.text('Sin motivo informado.'), findsOneWidget);
  });

  testWidgets('a null reason falls back to "Sin motivo informado."', (
    tester,
  ) async {
    await pump(tester, _change(PendingStatus.rejected));

    await tester.tap(find.text('Rechazado'));
    await tester.pumpAndSettle();

    expect(find.text('Sin motivo informado.'), findsOneWidget);
  });
}
