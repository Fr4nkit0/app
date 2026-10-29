import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/visits/presentation/widgets/visit_debt_banner.dart';

void main() {
  testWidgets('shows the debt as "Debe \$X", like the lists', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: VisitDebtBanner(debtAmount: 4200, onTap: null)),
      ),
    );

    expect(find.text('Debe \$4.200'), findsOneWidget);
    expect(find.textContaining('-'), findsNothing);
  });
}
