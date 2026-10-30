import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// The customer account the driver sees: the balance downloaded from the
/// server plus the sales and minus the payments not yet sent (a pending
/// cancellation takes its record back out).
///
/// The only module that reads or writes the customer balance. Every local
/// sale or payment posts a movement at once, a rejected one is posted back
/// out, and every download reconciles it with the server's value.
class CustomerAccount {
  CustomerAccount(this._db);

  final AppDatabase _db;

  /// Moves the account of [customerId] by [delta] (positive: owes more).
  Future<void> post(
    String customerId,
    double delta, {
    String? lastEntryId,
  }) async {
    final existing = await (_db.select(
      _db.customerBalanceTable,
    )..where((t) => t.customerId.equals(customerId))).getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.customerBalanceTable).insert(
            CustomerBalanceTableCompanion.insert(
              customerId: customerId,
              currentBalance: Value(delta),
              lastEntryId: Value(lastEntryId),
            ),
          );
      return;
    }
    await (_db.update(_db.customerBalanceTable)
          ..where((t) => t.customerId.equals(customerId)))
        .write(
      CustomerBalanceTableCompanion(
        currentBalance: Value(existing.currentBalance + delta),
        lastEntryId: lastEntryId == null
            ? const Value.absent()
            : Value(lastEntryId),
        lastModifiedDate: Value(DateTime.now()),
      ),
    );
  }

  /// The balance of [customerId]; 0 while they have no account.
  Stream<double> watchBalance(String customerId) {
    return (_db.select(_db.customerBalanceTable)
          ..where((t) => t.customerId.equals(customerId)))
        .watchSingleOrNull()
        .map((row) => row?.currentBalance ?? 0.0);
  }

  /// The balance of [customerId]; 0 while they have no account.
  Future<double> balanceOf(String customerId) async =>
      (await (_db.select(_db.customerBalanceTable)
                ..where((t) => t.customerId.equals(customerId)))
              .getSingleOrNull())
          ?.currentBalance ??
      0.0;

  /// Balances keyed by customer, for the [customerIds] that have an account.
  Future<Map<String, double>> balancesOf(Iterable<String> customerIds) async {
    final rows = await (_db.select(
      _db.customerBalanceTable,
    )..where((t) => t.customerId.isIn(customerIds))).get();
    return {for (final row in rows) row.customerId: row.currentBalance};
  }

  /// The table to list in a custom query's `readsFrom` so it follows the
  /// balances it reads back with [balanceIn].
  ResultSetImplementation<HasResultSet, dynamic> get watchedTable =>
      _db.customerBalanceTable;

  /// Left-joins a query to the account of [customerId], so a watched query
  /// also follows the balance; read it back with [balanceIn].
  Join balanceJoin(Expression<String> customerId) => leftOuterJoin(
    _db.customerBalanceTable,
    _db.customerBalanceTable.customerId.equalsExp(customerId),
  );

  /// The balance of a row from a query joined with [balanceJoin]; 0 when
  /// the customer has no account.
  double balanceIn(TypedResult row) =>
      row.readTableOrNull(_db.customerBalanceTable)?.currentBalance ?? 0.0;

  /// Stores the balance the server computed for [customerId], plus the
  /// sales and minus the payments the server has not received yet.
  Future<void> reconcile(
    String customerId,
    double serverBalance, {
    int? serverId,
    Value<bool> enabled = const Value.absent(),
  }) async {
    final pending = await pendingDelta(customerId);
    await _db.into(_db.customerBalanceTable).insertOnConflictUpdate(
          CustomerBalanceTableCompanion.insert(
            customerId: customerId,
            currentBalance: Value(serverBalance + pending),
            enabled: enabled,
            serverId: serverId == null ? const Value.absent() : Value(serverId),
          ),
        );
  }

  /// Pending sales minus pending payments of [customerId], minus the sales
  /// and plus the payments whose cancellation is pending.
  Future<double> pendingDelta(String customerId) async {
    String pendingIds(int entity) =>
        '(SELECT entity_id FROM pending_changes '
        'WHERE entity = ?$entity AND status = ?6)';
    String sales(int entity) =>
        '(SELECT COALESCE(SUM(s.total_amount), 0.0) FROM sales s '
        'WHERE s.customer_id = ?1 AND s.sale_id IN ${pendingIds(entity)})';
    String payments(int entity) =>
        '(SELECT COALESCE(SUM(p.amount), 0.0) FROM payments p '
        'WHERE p.customer_id = ?1 AND p.payment_id IN ${pendingIds(entity)})';
    final row = await _db.customSelect(
      'SELECT ${sales(2)} - ${payments(3)} - ${sales(4)} + ${payments(5)} '
      'AS delta',
      variables: [
        Variable.withString(customerId),
        Variable.withString(PendingEntity.sale.wireName),
        Variable.withString(PendingEntity.payment.wireName),
        Variable.withString(PendingEntity.saleCancellation.wireName),
        Variable.withString(PendingEntity.paymentCancellation.wireName),
        Variable.withString(PendingStatus.pending.wireName),
      ],
      readsFrom: {_db.saleTable, _db.paymentTable, _db.pendingChangeTable},
    ).getSingle();
    return row.read<double>('delta');
  }
}
