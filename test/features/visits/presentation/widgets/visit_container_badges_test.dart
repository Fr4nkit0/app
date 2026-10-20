import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/visits/presentation/widgets/visit_custody_banner.dart';

void main() {
  testWidgets('both container badges fit a narrow phone without overflowing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            // Width left for the badges on a 360dp phone inside the visit banner.
            child: SizedBox(width: 210, child: VisitContainerBadges(bidon: 15, sifon: 120)),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Bidón 20L: '), findsOneWidget);
    expect(find.text('Sifón 1.5L: '), findsOneWidget);
  });
}
