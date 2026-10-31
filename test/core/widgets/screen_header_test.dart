import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/widgets/screen_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the back button is labelled for TalkBack', (tester) async {
    final semantics = tester.ensureSemantics();
    var backs = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ScreenHeader(
            title: 'Nueva Venta',
            onBackPressed: () => backs++,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Volver'), findsOneWidget);
    final node = find.semantics
        .byPredicate((node) => node.tooltip == 'Volver')
        .evaluate()
        .single;
    expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    await tester.tap(find.byTooltip('Volver'));
    expect(backs, 1);
    semantics.dispose();
  });
}
