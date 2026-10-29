import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/payments/data/repositories/customer_account.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

void main() {
  late AppDatabase db;
  late CustomerAccount account;
  late PendingChangeRepository queue;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    account = CustomerAccount(db);
    queue = DriftPendingChangeRepository(db);
    for (final id in ['ana', 'beto']) {
      await db
          .into(db.customerTable)
          .insert(CustomerTableCompanion.insert(customerId: Value(id), name: id));
    }
  });

  tearDown(() => db.close());

  Future<void> pendingSale(String id, String customerId, double total) async {
    await db.into(db.saleTable).insert(
          SaleTableCompanion.insert(
            saleId: Value(id),
            customerId: customerId,
            totalAmount: total,
            paymentMethod: 'credit',
            quantity: 0,
            shipping_amount: 0,
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.sale,
      entityId: id,
      action: PendingAction.insert,
    );
  }

  Future<void> pendingPayment(String id, String customerId, double amount) async {
    await db.into(db.paymentTable).insert(
          PaymentTableCompanion.insert(
            paymentId: Value(id),
            customerId: customerId,
            amount: amount,
            paymentMethod: 'EFECTIVO',
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.payment,
      entityId: id,
      action: PendingAction.insert,
    );
  }

  group('post', () {
    test('opens the account of a customer without one', () async {
      await account.post('ana', 250);

      expect(await account.balanceOf('ana'), 250);
    });

    test('moves an existing account by the delta', () async {
      await account.post('ana', 250);
      await account.post('ana', -100);

      expect(await account.balanceOf('ana'), 150);
    });
  });

  group('watchBalance', () {
    test('is 0 for a customer without an account', () async {
      expect(await account.watchBalance('ana').first, 0);
    });

    test('follows posted movements', () async {
      await account.post('ana', 80);

      expect(await account.watchBalance('ana').first, 80);
    });
  });

  test('balancesOf returns the accounts of the customers that have one', () async {
    await account.post('ana', 10);

    expect(await account.balancesOf(['ana', 'beto']), {'ana': 10});
  });

  test('pendingDelta is the pending sales minus the pending payments', () async {
    await pendingSale('s1', 'ana', 300);
    await pendingPayment('p1', 'ana', 100);
    await pendingSale('s-beto', 'beto', 999);

    expect(await account.pendingDelta('ana'), 200);
  });

  group('reconcile', () {
    test('without pending changes stores the server value', () async {
      await account.post('ana', 9999);

      await account.reconcile('ana', 250.75);

      expect(await account.balanceOf('ana'), 250.75);
    });

    test('adds the pending sales and subtracts the pending payments', () async {
      await pendingSale('s1', 'ana', 300);
      await pendingPayment('p1', 'ana', 100);

      await account.reconcile('ana', 1500.5);

      expect(await account.balanceOf('ana'), 1500.5 + 300 - 100);
    });

    test('a sent sale is already in the server value', () async {
      await pendingSale('s1', 'ana', 300);
      await queue.markSent([(await queue.getPending()).single.id]);

      await account.reconcile('ana', 1000);

      expect(await account.balanceOf('ana'), 1000);
    });
  });

  test('a query joined to the account reads the balance, 0 without one', () async {
    await account.post('ana', 42);

    final rows = await (db.select(db.customerTable).join([
      account.balanceJoin(db.customerTable.customerId),
    ])..orderBy([OrderingTerm.asc(db.customerTable.customerId)])).get();

    expect(rows.map(account.balanceIn), [42, 0]);
  });
}
