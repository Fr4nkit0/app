import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';

/// The sales and payments the office cancelled, as the pull reported them
/// (`cancelled_by_admin`), so the driver sees who cancelled them.
///
/// Kept in the sync bookkeeping table, one key per record, since the
/// record tables have no column for it.
class AdminCancellations {
  AdminCancellations(this._db);

  final AppDatabase _db;

  static const _salePrefix = 'cancelled_by_admin/sale/';
  static const _paymentPrefix = 'cancelled_by_admin/payment/';

  /// Records whether the office cancelled the sale [saleId].
  Future<void> setSale(String saleId, {required bool byAdmin}) =>
      _set('$_salePrefix$saleId', byAdmin);

  /// Records whether the office cancelled the payment [paymentId].
  Future<void> setPayment(String paymentId, {required bool byAdmin}) =>
      _set('$_paymentPrefix$paymentId', byAdmin);

  /// Ids of the sales the office cancelled.
  Future<Set<String>> saleIds() => _ids(_salePrefix);

  /// Ids of the payments the office cancelled.
  Future<Set<String>> paymentIds() => _ids(_paymentPrefix);

  /// The table to follow so a watched list notices a new admin flag.
  TableInfo<Table, dynamic> get watchedTable => _db.syncStateTable;

  Future<void> _set(String key, bool byAdmin) async {
    if (!byAdmin) {
      await (_db.delete(
        _db.syncStateTable,
      )..where((t) => t.key.equals(key))).go();
      return;
    }
    await _db
        .into(_db.syncStateTable)
        .insertOnConflictUpdate(
          SyncStateTableCompanion.insert(key: key, value: 'true'),
        );
  }

  Future<Set<String>> _ids(String prefix) async {
    final rows = await (_db.select(
      _db.syncStateTable,
    )..where((t) => t.key.like('$prefix%'))).get();
    return {for (final row in rows) row.key.substring(prefix.length)};
  }
}
