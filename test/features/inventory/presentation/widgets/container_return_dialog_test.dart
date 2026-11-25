import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/inventory/domain/models/container_exchange.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/presentation/widgets/container_return_dialog.dart';

const _jug = ContainerType(id: 1, code: 'JUG', label: 'Bidón 20L');
const _siphon = ContainerType(id: 2, code: 'SIPHON', label: 'Sifón 1.5L');
const _skeleton = ContainerType(id: 3, code: 'ESQUELETO', label: 'Esqueleto');

void main() {
  late List<Map<String, int>> confirmed;

  Future<void> pump(
    WidgetTester tester, {
    Map<String, int> custody = const {'JUG': 2, 'SIPHON': 0},
    Map<String, int> initialReturns = const {},
  }) async {
    confirmed = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [MarilinTokens.light]),
        home: Scaffold(
          body: ContainerReturnDialog(
            containerTypes: const [_jug, _siphon],
            custody: custody,
            initialReturns: initialReturns,
            onConfirm: (exchange) => confirmed.add(exchange.returns),
          ),
        ),
      ),
    );
  }

  Finder plus(String label) => find.ancestor(
    of: find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
      matching: find.byTooltip('Sumar'),
    ),
    matching: find.byType(IconButton),
  );

  testWidgets('renders every container type by label with the visit copy', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Registrar Retorno de Envases'), findsOneWidget);
    expect(
      find.text(
        'Ajustá la cantidad de envases vacíos que devuelve el cliente.',
      ),
      findsOneWidget,
    );
    expect(find.text('Bidón 20L'), findsOneWidget);
    expect(find.text('Sifón 1.5L'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('a type can be returned up to the customer custody', (
    tester,
  ) async {
    await pump(tester);

    IconButton plusOf(String label) => tester.widget<IconButton>(plus(label));

    expect(plusOf('Sifón 1.5L').onPressed, isNull);
    await tester.tap(plus('Bidón 20L'));
    await tester.pump();
    await tester.tap(plus('Bidón 20L'));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    expect(plusOf('Bidón 20L').onPressed, isNull);
  });

  testWidgets('confirm hands back the returns per code', (tester) async {
    await pump(tester);

    await tester.tap(plus('Bidón 20L'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(confirmed, [
      {'JUG': 1, 'SIPHON': 0},
    ]);
  });

  testWidgets('initial returns above the custody start at the custody', (
    tester,
  ) async {
    await pump(
      tester,
      custody: const {'JUG': 5, 'SIPHON': 0},
      initialReturns: const {'JUG': 10, 'SIPHON': 4},
    );

    expect(find.text('10'), findsNothing);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(tester.widget<IconButton>(plus('Bidón 20L')).onPressed, isNull);

    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(confirmed, [
      {'JUG': 5, 'SIPHON': 0},
    ]);
  });

  testWidgets('starts from the initial returns and takes custom copy', (
    tester,
  ) async {
    confirmed = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [MarilinTokens.light]),
        home: Scaffold(
          body: ContainerReturnDialog(
            containerTypes: const [_jug],
            custody: const {'JUG': 5},
            initialReturns: const {'JUG': 3},
            title: 'Retorno de Envases',
            message: 'Confirmá o ajustá.',
            confirmLabel: 'Confirmar',
            onConfirm: (exchange) => confirmed.add(exchange.returns),
          ),
        ),
      ),
    );

    expect(find.text('Retorno de Envases'), findsOneWidget);
    expect(find.text('Confirmá o ajustá.'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byTooltip('Restar'));
    await tester.pump();
    await tester.tap(find.text('Confirmar'));
    await tester.pump();

    expect(confirmed, [
      {'JUG': 2},
    ]);
  });

  group('skeleton', () {
    late List<ContainerExchange> exchanges;

    Future<void> pumpWithSkeleton(WidgetTester tester) async {
      exchanges = [];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MarilinTokens.light]),
          home: Scaffold(
            body: ContainerReturnDialog(
              containerTypes: const [_jug, _skeleton],
              custody: const {'JUG': 1, 'ESQUELETO': 0},
              onConfirm: exchanges.add,
            ),
          ),
        ),
      );
    }

    Finder stepper(String label, String tooltip) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Row)).first,
      matching: find.byTooltip(tooltip),
    );

    testWidgets('shows Entregar and Retirar with the balance', (tester) async {
      await pumpWithSkeleton(tester);

      expect(find.text('Esqueleto'), findsOneWidget);
      expect(find.text('Saldo del cliente: 0'), findsOneWidget);
      expect(find.text('Entregar'), findsOneWidget);
      expect(find.text('Retirar'), findsOneWidget);
    });

    testWidgets('delivers and returns past the balance; others stay capped', (
      tester,
    ) async {
      await pumpWithSkeleton(tester);

      await tester.tap(stepper('Entregar', 'Sumar'));
      await tester.pump();
      await tester.tap(stepper('Retirar', 'Sumar'));
      await tester.pump();
      await tester.tap(stepper('Retirar', 'Sumar'));
      await tester.pump();
      await tester.tap(plus('Bidón 20L'));
      await tester.pump();
      expect(tester.widget<IconButton>(plus('Bidón 20L')).onPressed, isNull);

      await tester.tap(find.text('Guardar'));
      await tester.pump();

      expect(exchanges.single.returns, {'JUG': 1, 'ESQUELETO': 2});
      expect(exchanges.single.deliveries, {'ESQUELETO': 1});
    });

    testWidgets('without the skeleton nothing is delivered', (tester) async {
      exchanges = [];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [MarilinTokens.light]),
          home: Scaffold(
            body: ContainerReturnDialog(
              containerTypes: const [_jug],
              custody: const {'JUG': 1},
              onConfirm: exchanges.add,
            ),
          ),
        ),
      );

      expect(find.text('Entregar'), findsNothing);
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(exchanges.single.deliveries, isEmpty);
    });
  });
}
