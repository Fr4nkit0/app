import '../../../core/services/database.helper.dart';
import '../../inventory/data/repositories/custody.dart';
import '../../payments/data/repositories/customer_account.dart';
import 'pull_applier.dart';

/// Server balances and custody replace the local ones, plus the local
/// movements the server has not received yet (ADR 0003).
class BalanceApplier implements PullApplier {
  BalanceApplier(this._db)
    : _account = CustomerAccount(_db),
      _custody = Custody(_db);

  final AppDatabase _db;
  final CustomerAccount _account;
  final Custody _custody;

  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final b in rows['customer_balances'] ?? const <Json>[]) {
      final customerId = await context.ids.customer(b['customer_id'] as int?);
      if (customerId == null) continue;
      await _account.reconcile(
        customerId,
        toDouble(b['current_balance']),
        serverId: b['id'] as int,
        enabled: enabledOf(b),
      );
    }
    final containerCodes = await _containerCodes();
    for (final b in rows['customer_container_balances'] ?? const <Json>[]) {
      final customerId = await context.ids.customer(b['customer_id'] as int?);
      final code = containerCodes[b['container_type_id'] as int];
      if (customerId == null || code == null) continue;
      await _custody.reconcile(
        customerId,
        code,
        (b['balance'] as num).toInt(),
        serverId: b['id'] as int,
        enabled: enabledOf(b),
      );
    }
  }

  /// Reconciles the balance and custody the bootstrap nests in [customer],
  /// stored locally as [customerId].
  Future<void> reconcileCustomer(String customerId, Json customer) async {
    final balance = customer['balance'] as Json?;
    if (balance != null) {
      await _account.reconcile(
        customerId,
        toDouble(balance['current_balance']),
      );
    }
    final containerBalances = jsonList(customer['container_balances']);
    if (containerBalances.isEmpty) return;
    final containerCodes = await _containerCodes();
    for (final b in containerBalances) {
      final code = containerCodes[b['container_type_id'] as int];
      if (code == null) continue;
      await _custody.reconcile(customerId, code, (b['balance'] as num).toInt());
    }
  }

  /// Container codes keyed by the catalog's server id.
  Future<Map<int, String>> _containerCodes() async => {
    for (final c in await _db.select(_db.containerTypeTable).get())
      c.id: c.code,
  };
}
