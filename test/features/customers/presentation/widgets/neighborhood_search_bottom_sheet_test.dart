import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/customers/presentation/widgets/neighborhood_search_bottom_sheet.dart';
import 'package:app/features/customers/domain/models/salta_neighborhoods.dart';

void main() {
  group('NeighborhoodSearchBottomSheet Widget Tests', () {
    testWidgets(
      'renders search box and shows filtered list items case-insensitively',
      (WidgetTester tester) async {
        String? selectedNeighborhood;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => NeighborhoodSearchBottomSheet(
                        neighborhoods: saltaNeighborhoods,
                        onSelected: (val) {
                          selectedNeighborhood = val;
                        },
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        // Open bottom sheet
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Find search field
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        // Verify that '1 de Mayo' is initially visible and '14 de Mayo' is initially visible
        expect(find.text('1 de Mayo'), findsOneWidget);
        expect(find.text('14 de Mayo'), findsOneWidget);

        // Filter by "Cerritos"
        await tester.enterText(searchField, 'Cerritos');
        await tester.pumpAndSettle();

        // "Tres Cerritos" should still be visible (case-insensitive substring match)
        expect(find.text('Tres Cerritos'), findsOneWidget);
        // "1 de Mayo" should NOT be visible
        expect(find.text('1 de Mayo'), findsNothing);

        // Select "Tres Cerritos"
        await tester.tap(find.text('Tres Cerritos'));
        await tester.pumpAndSettle();

        // Bottom sheet should be closed and callback triggered
        expect(find.byType(NeighborhoodSearchBottomSheet), findsNothing);
        expect(selectedNeighborhood, 'Tres Cerritos');
      },
    );

    testWidgets('implements scroll-based pagination with page size of 15', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => NeighborhoodSearchBottomSheet(
                      neighborhoods: saltaNeighborhoods,
                      onSelected: (_) {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify that the ListView's itemCount is 15 initially.
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);
      final ListView listViewInitially = tester.widget(listViewFinder);
      expect(listViewInitially.childrenDelegate.estimatedChildCount, 15);

      // Scroll to the bottom of the list view.
      final scrollableFinder = find.descendant(
        of: find.byType(NeighborhoodSearchBottomSheet),
        matching: find.byType(ListView),
      );
      expect(scrollableFinder, findsOneWidget);

      // Scroll down by 800 pixels to trigger lazy load.
      await tester.drag(scrollableFinder, const Offset(0, -800));
      await tester.pumpAndSettle();

      // Verify that the ListView's itemCount increased to 30.
      final ListView listViewAfterScroll = tester.widget(listViewFinder);
      expect(listViewAfterScroll.childrenDelegate.estimatedChildCount, 30);
    });
  });

  testWidgets('searching Centro does not list Servicio Penitenciario', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeighborhoodSearchBottomSheet(
            neighborhoods: const ['Centro', 'Servicio Penitenciario'],
            onSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Centro');
    await tester.pumpAndSettle();

    expect(find.text('Servicio Penitenciario'), findsNothing);
    expect(find.text('Centro'), findsWidgets);
  });
}
