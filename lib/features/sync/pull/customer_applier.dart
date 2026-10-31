import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../data/repositories/removed_customers.dart';
import '../data/repositories/server_shadow.dart';
import 'pull_applier.dart';

/// Customers, matched by server id or, for one created on the device, by
/// its client uuid. A customer with unsent changes keeps its local copy;
/// the server values it skipped are kept for a rollback of those changes.
///
/// Customers listed in `customers_removed` were reassigned to another
/// driver and are hidden ([RemovedCustomers]); one the server sends again
/// is shown again.
class CustomerApplier implements PullApplier {
  CustomerApplier(this._db)
    : _shadow = ServerShadow(_db),
      _removed = RemovedCustomers(_db);

  final AppDatabase _db;
  final ServerShadow _shadow;
  final RemovedCustomers _removed;

  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final c in rows['customers'] ?? const <Json>[]) {
      await upsert(c, context);
    }
    for (final r in rows['customers_removed'] ?? const <Json>[]) {
      await _removed.hide(
        serverId: r['customer_id'] as int?,
        clientUuid: r['client_uuid'] as String?,
        removedAt: '${r['removed_at']}',
      );
    }
  }

  /// Stores [c] and returns its local id.
  Future<String> upsert(Json c, PullContext context) async {
    final serverId = c['id'] as int;
    final clientUuid = c['client_uuid'] as String?;
    final existing =
        await (_db.select(_db.customerTable)..where(
              (t) =>
                  t.serverId.equals(serverId) |
                  (clientUuid == null
                      ? const Constant(false)
                      : t.customerId.equals(clientUuid)),
            ))
            .getSingleOrNull();

    final fields = fieldsOf(c);
    final String localId;
    if (existing == null) {
      localId =
          (await _db
                  .into(_db.customerTable)
                  .insertReturning(
                    fields.copyWith(
                      customerId: clientUuid == null
                          ? const Value.absent()
                          : Value(clientUuid),
                    ),
                  ))
              .customerId;
    } else {
      if (context.unsent.customers.contains(existing.customerId)) {
        await _shadow.storePulledCustomer(existing.customerId, fields);
      } else {
        await (_db.update(_db.customerTable)
              ..where((t) => t.customerId.equals(existing.customerId)))
            .write(fields);
      }
      localId = existing.customerId;
      await _removed.show(localId);
    }
    context.ids.recordCustomer(serverId, localId);
    return localId;
  }

  /// The local columns of the server customer row [c], server id included.
  static CustomerTableCompanion fieldsOf(Json c) => CustomerTableCompanion(
    name: Value(c['name'] as String),
    phone: Value(c['phone_number'] as String?),
    enabled: enabledOf(c),
    serverId: Value(c['id'] as int),
  );
}
