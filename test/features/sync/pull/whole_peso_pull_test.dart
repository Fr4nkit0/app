import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/pull/agreement_applier.dart';
import 'package:app/features/sync/pull/balance_applier.dart';
import 'package:app/features/sync/pull/payment_applier.dart';
import 'package:app/features/sync/pull/product_applier.dart';
import 'package:app/features/sync/pull/pull_applier.dart';
import 'package:app/features/sync/pull/sale_applier.dart';

import 'pull_support.dart';

/// Money downloaded as a number or a decimal string is stored rounded to
/// the nearest whole peso.
void main() {
  group('toPesos', () {
    test('rounds a decimal string to the nearest peso', () {
      expect(toPesos('1500.00'), 1500);
      expect(toPesos('19500.07'), 19500);
      expect(toPesos('3999.99'), 4000);
      expect(toPesos('-200.50'), -201);
    });

    test('rounds a number to the nearest peso', () {
      expect(toPesos(19500.07), 19500);
      expect(toPesos(3999.99), 4000);
      expect(toPesos(1500), 1500);
    });
  });

  group('appliers', () {
    late AppDatabase db;

    setUp(() async {
      db = memoryDatabase();
      await seedCustomer(db, id: 'cust-1', serverId: 11);
      await seedProduct(db, id: 'prod-1', serverId: 21);
      await db
          .into(db.paymentMethodTable)
          .insert(
            PaymentMethodTableCompanion.insert(
              id: const Value(1),
              code: 'CASH',
              name: 'Efectivo',
            ),
          );
    });
    tearDown(() => db.close());

    test('a product price "3999.99" is stored as 4000', () async {
      await ProductApplier(db).applyChanges({
        'products': [
          {'id': 21, 'name': 'Agua', 'description': null, 'price': '3999.99'},
        ],
      }, await pullContext(db));

      final row = await db.select(db.productTable).getSingle();
      expect(row.price, 4000);
    });

    test('an agreement unit price 19500.07 is stored as 19500', () {
      final fields = AgreementApplier.fieldsOf({
        'id': 1,
        'unit_price': 19500.07,
        'valid_from': '2026-10-01',
        'valid_to': null,
        'reason': null,
      });
      expect(fields.unitPrice.value, 19500);
    });

    test('a balance "3999.99" is reconciled as 4000 and the rounding '
        'uploads no balance correction (S6)', () async {
      await BalanceApplier(db).applyChanges({
        'customer_balances': [
          {'id': 400, 'customer_id': 11, 'current_balance': '3999.99'},
        ],
      }, await pullContext(db));

      expect(
        (await db.select(db.customerBalanceTable).getSingle()).currentBalance,
        4000,
      );
      expect(await db.select(db.balanceCorrectionTable).get(), isEmpty);
      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    });

    test('a payment of "3999.99" is stored as 4000', () async {
      await PaymentApplier(db).storeToday([
        {
          'id': 70,
          'client_uuid': null,
          'customer_id': 11,
          'payment_method_id': 1,
          'amount': '3999.99',
          'paid_at': '2026-11-27T12:00:00Z',
          'status': 'confirmed',
        },
      ], await pullContext(db));

      expect((await db.select(db.paymentTable).getSingle()).amount, 4000);
    });

    test(
      'a sale of "1500.00" with a line of 19500.07 rounds each amount',
      () async {
        await SaleApplier(db).storeToday([
          {
            'id': 80,
            'client_uuid': null,
            'customer_id': 11,
            'total': '1500.00',
            'is_credit_sale': true,
            'date': '2026-11-27T12:00:00Z',
            'details': [
              {
                'id': 81,
                'product_id': 21,
                'quantity': 2,
                'unit_price': 19500.07,
              },
            ],
          },
        ], await pullContext(db));

        expect((await db.select(db.saleTable).getSingle()).totalAmount, 1500);
        final item = await db.select(db.saleItemTable).getSingle();
        expect(item.unitPrice, 19500);
        expect(item.subtotal, 39000);
      },
    );
  });
}
