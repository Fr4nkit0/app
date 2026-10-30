import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/visits/presentation/widgets/visit_custody_banner.dart';

const _types = [
  ContainerType(id: 1, code: 'JUG', label: 'Bidón 20L'),
  ContainerType(id: 2, code: 'SIPHON', label: 'Sifón 1.5L'),
];

const _badges = VisitContainerBadges(
  containerTypes: _types,
  custody: {'JUG': 15, 'SIPHON': 120},
);

void main() {
  testWidgets('both container badges fit a narrow phone without overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            // Width left for the badges on a 360dp phone inside the visit banner.
            child: SizedBox(width: 210, child: _badges),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Bidón 20L: '), findsOneWidget);
    expect(find.text('Sifón 1.5L: '), findsOneWidget);
  });

  testWidgets('both container badges stay on a single row', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 210, child: _badges)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getCenter(find.text('Bidón 20L: ')).dy,
      tester.getCenter(find.text('Sifón 1.5L: ')).dy,
    );
    expect(find.text('15'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
  });

  testWidgets('a catalog type the customer does not hold shows zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VisitContainerBadges(
            containerTypes: _types,
            custody: {'JUG': 4},
          ),
        ),
      ),
    );

    expect(find.text('4'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
