import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/presentation/screens/sale_step3_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/real_fonts.dart';

const _longName =
    'Distribuidora Hermanos Rodríguez y Compañía Sociedad Anónima';

void main() {
  setUpAll(() async {
    expect(
      await loadRealFonts(),
      isTrue,
      reason: 'Roboto was not found in the Flutter SDK cache',
    );
  });

  testWidgets('a 60-character name stays on one line with an ellipsis', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final draft = SaleDraftState(
      customer: Customer(
        id: 'c-1',
        name: _longName,
        addresses: const [],
        preferences: const [],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SaleStep3ClientCard(draft: draft)),
      ),
    );

    final name = tester.widget<Text>(find.text(_longName));
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
