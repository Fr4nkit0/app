import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/route/presentation/widgets/route_progress_line.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required int done,
    required int total,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [MarilinTokens.light]),
      home: Scaffold(
        body: RouteProgressLine(done: done, total: total),
      ),
    ),
  );

  testWidgets('one pending stop is singular', (tester) async {
    await pump(tester, done: 8, total: 9);

    expect(find.text('8 de 9 paradas · 1 pendiente'), findsOneWidget);
  });

  testWidgets('several pending stops are plural', (tester) async {
    await pump(tester, done: 1, total: 3);

    expect(find.text('1 de 3 paradas · 2 pendientes'), findsOneWidget);
  });

  testWidgets('no pending stops are plural', (tester) async {
    await pump(tester, done: 3, total: 3);

    expect(find.text('3 de 3 paradas · 0 pendientes'), findsOneWidget);
  });
}
