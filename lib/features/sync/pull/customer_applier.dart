import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// Customers, matched by server id or, for one created on the device, by
/// its client uuid. A customer with unsent changes keeps its local copy.
class CustomerApplier implements PullApplier {
  CustomerApplier(this._db);

  final AppDatabase _db;

  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final c in rows['customers'] ?? const <Json>[]) {
      await upsert(c, context);
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

    final fields = CustomerTableCompanion(
      name: Value(c['name'] as String),
      phone: Value(c['phone_number'] as String?),
      enabled: enabledOf(c),
      serverId: Value(serverId),
    );
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
      if (!context.unsent.customers.contains(existing.customerId)) {
        await (_db.update(_db.customerTable)
              ..where((t) => t.customerId.equals(existing.customerId)))
            .write(fields);
      }
      localId = existing.customerId;
    }
    context.ids.recordCustomer(serverId, localId);
    return localId;
  }
}
