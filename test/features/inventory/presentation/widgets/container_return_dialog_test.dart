import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/presentation/widgets/container_return_dialog.dart';

const _jug = ContainerType(id: 1, code: 'JUG', label: 'Bidón 20L');
const _siphon = ContainerType(id: 2, code: 'SIPHON', label: 'Sifón 1.5L');

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
            onConfirm: confirmed.add,
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
            onConfirm: confirmed.add,
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
}
