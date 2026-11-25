import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/presentation/widgets/container_return_dialog.dart';

const _skeleton = ContainerType(id: 3, code: 'ESQUELETO', label: 'Esqueleto');
const _jug = ContainerType(id: 1, code: 'JUG', label: 'Bidón 20L');
const _siphon = ContainerType(id: 2, code: 'SIPHON', label: 'Sifón 1.5L');

void main() {
  late List<Map<String, int>> confirmed;

  Future<void> pump(WidgetTester tester) async {
    confirmed = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [MarilinTokens.light]),
        home: Scaffold(
          body: ContainerReturnDialog(
            // The skeleton comes first in the catalog on purpose.
            containerTypes: const [_skeleton, _jug, _siphon],
            custody: const {'JUG': 2, 'SIPHON': 1, 'ESQUELETO': 1},
            initialReturns: const {'JUG': 1, 'ESQUELETO': 2},
            onConfirm: confirmed.add,
          ),
        ),
      ),
    );
  }

  testWidgets('every type, the skeleton included, follows the catalog order', (
    tester,
  ) async {
    await pump(tester);

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Esqueleto'), lessThan(top('Bidón 20L')));
    expect(top('Bidón 20L'), lessThan(top('Sifón 1.5L')));
  });

  testWidgets('the skeleton starts above its custody and is saved as such', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(confirmed, [
      {'ESQUELETO': 2, 'JUG': 1, 'SIPHON': 0},
    ]);
  });
}
