import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/widgets/step_address_view.dart';

void main() {
  Future<List<String>> pumpView(
    WidgetTester tester, {
    required String neighborhood,
  }) async {
    final changes = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StepAddressView(
              street: 'Mitre 50',
              neighborhood: neighborhood,
              apartment: '',
              floor: '',
              visualReference: '',
              onStreetChanged: (_) {},
              onNeighborhoodChanged: changes.add,
              onApartmentChanged: (_) {},
              onFloorChanged: (_) {},
              onVisualReferenceChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  testWidgets('the neighborhood is labeled optional', (tester) async {
    await pumpView(tester, neighborhood: '');

    expect(find.text('Barrio (opcional)'), findsOneWidget);
    expect(find.text('El barrio es requerido'), findsNothing);
  });

  testWidgets('a picked neighborhood can be cleared', (tester) async {
    final changes = await pumpView(tester, neighborhood: 'Centro');

    await tester.tap(find.byTooltip('Quitar barrio'));
    await tester.pump();

    expect(changes, ['']);
  });

  testWidgets('an empty neighborhood offers no clear action', (tester) async {
    await pumpView(tester, neighborhood: '');

    expect(find.byTooltip('Quitar barrio'), findsNothing);
  });
}
