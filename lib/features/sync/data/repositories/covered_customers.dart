import 'package:drift/drift.dart';

import '../../../../core/services/database.helper.dart';
import '../../domain/models/pending_change.dart';
import '../../pull/pull_applier.dart' show dateOnly;
import 'removed_customers.dart';
import 'server_shadow.dart';

/// Forgets, on this device only, the customers the driver got through
/// covered stops (`customers.is_cover`), once they are done with:
///
/// - their cover day ended (no stop of theirs is on a route of today or
///   later; a customer with no stops left counts as ended), or the server
///   listed them in `customers_removed` ([RemovedCustomers]); and
/// - everything recorded on them is settled: no queue entry of any of their
///   records is `pending`, `rejected` or `awaiting_approval`.
///
/// The customer and every row of its own go in one transaction with direct
/// deletes, like applying server data: nothing is queued and the server is
/// never told; it keeps all of it. An own customer (`is_cover` false) is
/// never touched.
class CoveredCustomerCleanup {
  CoveredCustomerCleanup(this._db, {DateTime Function()? today})
    : _today = today ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _today;

  /// Queue states that keep a customer: something still has to reach the
  /// server or the driver still has to look at it.
  static final _unsettled = [
    PendingStatus.pending,
    PendingStatus.rejected,
    PendingStatus.awaitingApproval,
  ].map((s) => s.wireName).toList();

  /// Every queued record by entity, with the customer it belongs to.
  static const _ownedSql =
      'owned(entity, id, customer_id) AS ('
      "SELECT 'customer', customer_id, customer_id FROM customers "
      "UNION ALL SELECT 'customer_address', address_id, customer_id "
      'FROM customer_addresses '
      "UNION ALL SELECT 'customer_preference', customer_preference_id, "
      'customer_id FROM customer_preferences '
      "UNION ALL SELECT 'customer_agreement', agreement_id, customer_id "
      'FROM customer_agreements '
      "UNION ALL SELECT 'route_stop', route_stop_id, customer_id "
      'FROM route_stops '
      "UNION ALL SELECT 'visit', visit_id, customer_id FROM visits "
      "UNION ALL SELECT 'sale', sale_id, customer_id FROM sales "
      "UNION ALL SELECT 'sale_cancellation', sale_id, customer_id FROM sales "
      "UNION ALL SELECT 'payment', payment_id, customer_id FROM payments "
      "UNION ALL SELECT 'payment_cancellation', payment_id, customer_id "
      'FROM payments '
      "UNION ALL SELECT 'container_movement', container_movement_id, "
      'customer_id FROM container_movements)';

  /// Forgets every covered customer that is done with; returns their ids.
  /// Runs in one transaction: a failure leaves every row in place.
  Future<List<String>> run() => _db.transaction(() async {
    final ids = await _eligible();
    for (final id in ids) {
      await _forget(id);
    }
    return ids;
  });

  Future<List<String>> _eligible() async {
    final rows = await _db
        .customSelect(
          'WITH $_ownedSql '
          'SELECT c.customer_id AS id FROM customers c '
          'WHERE c.is_cover = 1 AND ('
          'NOT EXISTS (SELECT 1 FROM route_stops s '
          'JOIN routes r ON r.route_id = s.route_id '
          'WHERE s.customer_id = c.customer_id AND r.route_date >= ?1) '
          'OR EXISTS (SELECT 1 FROM sync_state '
          'WHERE key = ?2 || c.customer_id)) '
          'AND NOT EXISTS (SELECT 1 FROM pending_changes p '
          'JOIN owned o ON o.entity = p.entity AND o.id = p.entity_id '
          'WHERE o.customer_id = c.customer_id AND p.status IN (?3, ?4, ?5))',
          variables: [
            Variable.withString(dateOnly(_today())),
            Variable.withString(RemovedCustomers.keyPrefix),
            for (final s in _unsettled) Variable.withString(s),
          ],
          readsFrom: {
            _db.customerTable,
            _db.routeStopTable,
            _db.routeTable,
            _db.syncStateTable,
            _db.pendingChangeTable,
          },
        )
        .get();
    return [for (final r in rows) r.read<String>('id')];
  }

  /// Deletes [customerId] and its rows; foreign keys are not enforced, so
  /// every child goes explicitly.
  Future<void> _forget(String customerId) async {
    Future<List<String>> idsOf<T extends Table, R>(
      TableInfo<T, R> table,
      GeneratedColumn<String> id,
      GeneratedColumn<String> owner,
    ) async {
      final query = _db.selectOnly(table)
        ..addColumns([id])
        ..where(owner.equals(customerId));
      return [for (final r in await query.get()) r.read(id)!];
    }

    final addresses = await idsOf(
      _db.customerAddressTable,
      _db.customerAddressTable.addressId,
      _db.customerAddressTable.customerId,
    );
    final preferences = await idsOf(
      _db.customerPreferenceTable,
      _db.customerPreferenceTable.customerPreferenceId,
      _db.customerPreferenceTable.customerId,
    );
    final sales = await idsOf(
      _db.saleTable,
      _db.saleTable.saleId,
      _db.saleTable.customerId,
    );
    final payments = await idsOf(
      _db.paymentTable,
      _db.paymentTable.paymentId,
      _db.paymentTable.customerId,
    );
    final owned = <PendingEntity, List<String>>{
      PendingEntity.customer: [customerId],
      PendingEntity.customerAddress: addresses,
      PendingEntity.customerPreference: preferences,
      PendingEntity.customerAgreement: await idsOf(
        _db.customerAgreementTable,
        _db.customerAgreementTable.agreementId,
        _db.customerAgreementTable.customerId,
      ),
      PendingEntity.routeStop: await idsOf(
        _db.routeStopTable,
        _db.routeStopTable.routeStopId,
        _db.routeStopTable.customerId,
      ),
      PendingEntity.visit: await idsOf(
        _db.visitTable,
        _db.visitTable.visitId,
        _db.visitTable.customerId,
      ),
      PendingEntity.sale: sales,
      PendingEntity.saleCancellation: sales,
      PendingEntity.payment: payments,
      PendingEntity.paymentCancellation: payments,
      PendingEntity.containerMovement: await idsOf(
        _db.containerMovementTable,
        _db.containerMovementTable.containerMovementId,
        _db.containerMovementTable.customerId,
      ),
    };

    for (final MapEntry(key: entity, value: ids) in owned.entries) {
      if (ids.isEmpty) continue;
      await (_db.delete(_db.pendingChangeTable)..where(
            (t) =>
                t.entity.equals(entity.wireName) &
                t.entityId.isIn(ids) &
                t.status.isNotIn(_unsettled),
          ))
          .go();
    }
    await (_db.delete(_db.syncStateTable)..where(
          (t) => t.key.isIn([
            RemovedCustomers.keyOf(customerId),
            ServerShadow.keyOf(PendingEntity.customer, customerId),
            for (final id in addresses)
              ServerShadow.keyOf(PendingEntity.customerAddress, id),
            for (final id in preferences)
              ServerShadow.keyOf(PendingEntity.customerPreference, id),
          ]),
        ))
        .go();

    await (_db.delete(
      _db.saleItemTable,
    )..where((t) => t.saleId.isIn(sales))).go();
    await (_db.delete(
      _db.saleTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.paymentTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.customerAccountEntryTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.customerBalanceTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.containerMovementTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.customerContainerBalanceTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.customerAgreementTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.visitTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.routeStopTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.customerAddressTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.customerPreferenceTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.customerTable,
    )..where((t) => t.customerId.equals(customerId))).go();
  }
}
