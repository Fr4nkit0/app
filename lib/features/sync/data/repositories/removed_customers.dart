import 'package:drift/drift.dart';

import '../../../../core/services/database.helper.dart';

/// Customers that were reassigned to another driver: hidden from Clientes
/// and from the sales customer picker, with every record of theirs kept, so
/// Historial and their own history still list them (APP-32).
///
/// Kept in `sync_state` under `removed_customer:<localId>` with the server's
/// `removed_at`, apart from `enabled`: a disabled customer is the office's
/// (or the driver's) decision and travels in the customer push, while a
/// reassignment is only about this device. A customer the pull brings again
/// in `customers` (reassigned back) shows again.
class RemovedCustomers {
  RemovedCustomers(this._db);

  static const keyPrefix = 'removed_customer:';

  final AppDatabase _db;

  static String keyOf(String customerId) => '$keyPrefix$customerId';

  /// Hides the local customer with [serverId] or, for one created on the
  /// device, with [clientUuid]; a customer the device does not know is
  /// ignored.
  Future<void> hide({
    required int? serverId,
    required String? clientUuid,
    required String removedAt,
  }) async {
    if (serverId == null && clientUuid == null) return;
    final customer =
        await (_db.select(_db.customerTable)
              ..where(
                (t) =>
                    (serverId == null
                        ? const Constant(false)
                        : t.serverId.equals(serverId)) |
                    (clientUuid == null
                        ? const Constant(false)
                        : t.customerId.equals(clientUuid)),
              )
              ..limit(1))
            .getSingleOrNull();
    if (customer == null) return;
    await _db
        .into(_db.syncStateTable)
        .insertOnConflictUpdate(
          SyncStateTableCompanion.insert(
            key: keyOf(customer.customerId),
            value: removedAt,
          ),
        );
  }

  /// Shows [customerId] again.
  Future<void> show(String customerId) => (_db.delete(
    _db.syncStateTable,
  )..where((t) => t.key.equals(keyOf(customerId)))).go();

  /// True for a customer row that is not hidden; [customerId] is the
  /// customer's local id column.
  static Expression<bool> isShown(
    AppDatabase db,
    Expression<String> customerId,
  ) => notExistsQuery(
    db.selectOnly(db.syncStateTable)
      ..addColumns([db.syncStateTable.key])
      ..where(
        db.syncStateTable.key.equalsExp(const Constant(keyPrefix) + customerId),
      ),
  );
}
