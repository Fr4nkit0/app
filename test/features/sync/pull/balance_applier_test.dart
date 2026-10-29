import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/pull/balance_applier.dart';

import 'pull_support.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = memoryDatabase();
    await seedCustomer(db, id: 'cust-1', serverId: 11);
    await db
        .into(db.containerTypeTable)
        .insert(
          ContainerTypeTableCompanion.insert(
            id: const Value(1),
            code: 'BIDON_20L',
          ),
        );
  });
  tearDown(() => db.close());

  test('a pull reconciles the balances of customers on the device', () async {
    await BalanceApplier(db).applyChanges({
      'customer_balances': [
        {'id': 400, 'customer_id': 11, 'current_balance': '250.00'},
        {'id': 401, 'customer_id': 99, 'current_balance': '10.00'},
      ],
      'customer_container_balances': [
        {'id': 1300, 'customer_id': 11, 'container_type_id': 1, 'balance': 3},
        {'id': 1301, 'customer_id': 11, 'container_type_id': 9, 'balance': 4},
        {'id': 1302, 'customer_id': 99, 'container_type_id': 1, 'balance': 5},
      ],
    }, await pullContext(db));

    final balance = await db.select(db.customerBalanceTable).getSingle();
    expect(balance.customerId, 'cust-1');
    expect(balance.currentBalance, 250);
    expect(balance.serverId, 400);
    final custody = await db
        .select(db.customerContainerBalanceTable)
        .getSingle();
    expect(custody.containerType, 'BIDON_20L');
    expect(custody.quantity, 3);
    expect(custody.serverId, 1300);
  });

  test('a bootstrap reconciles the balances nested in the customer', () async {
    await BalanceApplier(db).reconcileCustomer('cust-1', {
      'id': 11,
      'balance': {'current_balance': '1500.50'},
      'container_balances': [
        {'id': 1300, 'container_type_id': 1, 'balance': 3},
        {'id': 1301, 'container_type_id': 9, 'balance': 4},
      ],
    });

    expect(
      (await db.select(db.customerBalanceTable).getSingle()).currentBalance,
      1500.5,
    );
    final custody = await db
        .select(db.customerContainerBalanceTable)
        .getSingle();
    expect(custody.containerType, 'BIDON_20L');
    expect(custody.quantity, 3);
  });
}
