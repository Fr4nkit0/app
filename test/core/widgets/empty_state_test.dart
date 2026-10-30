import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/widgets/empty_state.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders a 52dp action that calls onAction', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        EmptyState(
          icon: Icons.route_outlined,
          title: 'Title',
          message: 'Message',
          actionLabel: 'Do it',
          onAction: () => taps++,
        ),
      ),
    );

    final button = find.widgetWithText(OutlinedButton, 'Do it');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(52));
    await tester.tap(button);
    expect(taps, 1);
  });

  testWidgets('renders no button without an action', (tester) async {
    await tester.pumpWidget(
      host(
        const EmptyState(
          icon: Icons.route_outlined,
          title: 'Title',
          message: 'Message',
        ),
      ),
    );

    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
  });

  testWidgets('a label without onAction renders a disabled button', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const EmptyState(
          icon: Icons.route_outlined,
          title: 'Title',
          message: 'Message',
          actionLabel: 'Wait',
        ),
      ),
    );

    final button = find.widgetWithText(OutlinedButton, 'Wait');
    expect(button, findsOneWidget);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
  });
}
