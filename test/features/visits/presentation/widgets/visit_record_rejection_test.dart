import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/providers/pending_change_repository_provider.dart';
import 'package:app/features/sync/presentation/widgets/sync_badge_container.dart';

void main() {
  testWidgets(
    'a rejected visit record shows a known server reason in Spanish',
    (tester) async {
      const stored = 'The visit belongs to another driver.';
      final change = PendingChange(
        id: 1,
        entity: PendingEntity.visit,
        entityId: 'visit-1',
        action: PendingAction.insert,
        status: PendingStatus.rejected,
        rejectionReason: stored,
        createdAt: DateTime(2026, 10, 30),
      );

      // The visit screen renders each record's badge through this container.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recordSyncStatusProvider.overrideWith(
              (ref, key) => Stream.value(change),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SyncBadgeContainer(
                  entity: PendingEntity.visit,
                  entityId: 'visit-1',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rechazado'));
      await tester.pumpAndSettle();

      expect(find.text('Pertenece a otro repartidor.'), findsOneWidget);
      expect(find.text(stored), findsNothing);
      expect(change.rejectionReason, stored);
    },
  );
}
