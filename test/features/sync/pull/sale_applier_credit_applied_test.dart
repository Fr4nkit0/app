import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/pull/sale_applier.dart';

import 'pull_support.dart';

/// A bootstrapped sale keeps the credit in favor it applied (S2); a server
/// that does not send it yet leaves 0.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = memoryDatabase();
    await seedCustomer(db, id: 'cust-1', serverId: 11);
    await seedProduct(db, id: 'prod-1', serverId: 21);
  });
  tearDown(() => db.close());

  Map<String, dynamic> sale(int id, {Object? creditApplied}) => {
    'id': id,
    'client_uuid': null,
    'customer_id': 11,
    'total': '17500.00',
    'is_credit_sale': false,
    'date': '2026-11-27T12:00:00Z',
    'credit_applied': ?creditApplied,
    'details': [
      {'id': id + 1, 'product_id': 21, 'quantity': 1, 'unit_price': 17500},
    ],
  };

  test('reads credit_applied, rounded to whole pesos, and 0 when absent',
      () async {
    await SaleApplier(db).storeToday([
      sale(80, creditApplied: '500.00'),
      sale(90),
    ], await pullContext(db));

    final rows = await db.select(db.saleTable).get();
    expect(
      {for (final r in rows) r.serverId: r.creditApplied},
      {80: 500, 90: 0},
    );
  });
}
