import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/presentation/widgets/neighborhood_picker_sheet.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpPicker(
    WidgetTester tester, {
    ValueChanged<String>? onSelected,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => NeighborhoodPickerSheet(
                    onSelected: onSelected ?? (_) {},
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  // Drift schedules a zero-duration timer when a watched query is cancelled.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  Future<void> store(int id, String name, {bool enabled = true}) => db
      .into(db.neighborhoodTable)
      .insert(
        NeighborhoodTableCompanion.insert(
          id: drift.Value(id),
          name: name,
          enabled: drift.Value(enabled),
        ),
      );

  testWidgets('lists the bundled Salta neighborhoods while the catalog is empty', (tester) async {
    await pumpPicker(tester);

    expect(find.text('1 de Mayo'), findsOneWidget);
    expect(find.text('14 de Mayo'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('lists only the enabled stored neighborhoods once synced', (tester) async {
    await tester.runAsync(() async {
      await store(1, 'Centro');
      await store(2, 'Barrio Nuevo');
      await store(3, 'Tres Cerritos', enabled: false);
    });
    String? selected;

    await pumpPicker(tester, onSelected: (name) => selected = name);

    expect(find.text('Barrio Nuevo'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('Tres Cerritos'), findsNothing);
    expect(find.text('1 de Mayo'), findsNothing);

    await tester.tap(find.text('Centro'));
    await tester.pumpAndSettle();
    expect(selected, 'Centro');
    expect(find.byType(NeighborhoodPickerSheet), findsNothing);

    await unmount(tester);
  });
}
