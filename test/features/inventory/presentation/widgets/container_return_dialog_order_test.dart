import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/inventory/domain/models/container_exchange.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/presentation/widgets/container_return_dialog.dart';

const _skeleton = ContainerType(id: 3, code: 'ESQUELETO', label: 'Esqueleto');
const _jug = ContainerType(id: 1, code: 'JUG', label: 'Bidón 20L');
const _siphon = ContainerType(id: 2, code: 'SIPHON', label: 'Sifón 1.5L');

void main() {
  late List<ContainerExchange> exchanges;

  Future<void> pump(WidgetTester tester) async {
    exchanges = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [MarilinTokens.light]),
        home: Scaffold(
          body: ContainerReturnDialog(
            // The skeleton comes first in the catalog on purpose.
            containerTypes: const [_skeleton, _jug, _siphon],
            custody: const {'JUG': 2, 'SIPHON': 1, 'ESQUELETO': 1},
            initialReturns: const {'JUG': 1, 'ESQUELETO': 2},
            onConfirm: exchanges.add,
          ),
        ),
      ),
    );
  }

  testWidgets('the skeleton block goes below the empty containers', (
    tester,
  ) async {
    await pump(tester);

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Bidón 20L'), lessThan(top('Sifón 1.5L')));
    expect(top('Sifón 1.5L'), lessThan(top('Esqueleto')));
    expect(top('Esqueleto'), lessThan(top('Entregar al cliente')));
  });

  testWidgets('the order on screen does not change what is saved', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Entregar al cliente'),
              matching: find.byType(Row),
            )
            .first,
        matching: find.byTooltip('Sumar'),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(exchanges.single.returns, {'ESQUELETO': 2, 'JUG': 1, 'SIPHON': 0});
    expect(exchanges.single.deliveries, {'ESQUELETO': 1});
  });
}
