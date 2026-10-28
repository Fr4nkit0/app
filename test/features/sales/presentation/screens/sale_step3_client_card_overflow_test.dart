import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/screens/sale_step3_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/real_fonts.dart';

const _longName =
    'Distribuidora Hermanos Rodríguez y Compañía Sociedad Anónima';
const _longProduct =
    'Agua mineral sin gas en bidón retornable de veinte litros edición familiar';

void main() {
  setUpAll(() async {
    expect(
      await loadRealFonts(),
      isTrue,
      reason: 'Roboto was not found in the Flutter SDK cache',
    );
  });

  testWidgets(
    'a long product name wraps without overflow and the card omits the customer name',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final draft = SaleDraftState(
        customer: Customer(
          id: 'c-1',
          name: _longName,
          addresses: const [],
          preferences: const [],
        ),
        items: [
          SaleItem(
            product: const Product(
              id: 'p-1',
              name: _longProduct,
              unitLabel: 'bidón',
              price: 1500,
            ),
            quantity: 2,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: SaleStep3ClientCard(draft: draft)),
        ),
      );

      expect(find.textContaining(_longProduct), findsOneWidget);
      expect(find.text(_longName), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
