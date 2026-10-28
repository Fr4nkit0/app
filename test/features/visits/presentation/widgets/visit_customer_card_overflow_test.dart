import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/visits/presentation/widgets/visit_customer_card.dart';
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

  testWidgets('a 60-character name wraps to two lines with an ellipsis', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: VisitCustomerCard(
              customerName: _longName,
              formattedAddress: 'Av. Belgrano 1234, Barrio Centro',
              phone: '3874000000',
            ),
          ),
        ),
      ),
    );

    final name = tester.widget<Text>(find.text(_longName));
    expect(name.maxLines, 2);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
