import '../../../core/services/database.helper.dart';
import '../domain/models/pending_change.dart';

/// Local rows that still have unsent or rejected changes; the server copy
/// must not overwrite them.
class Unsent {
  const Unsent({
    required this.customers,
    required this.stops,
    required this.visits,
    required this.sales,
    this.addresses = const {},
    this.addressOwners = const {},
  });

  final Set<String> customers;
  final Set<String> stops;
  final Set<String> visits;
  final Set<String> sales;

  /// Addresses with their own unsent change.
  final Set<String> addresses;

  /// Customers with an unsent address change: a primary switch touches two
  /// addresses, so every address of theirs keeps its local values.
  final Set<String> addressOwners;

  bool get hasSales => sales.isNotEmpty;

  /// Reads the queue; a stop with an unsent visit counts as unsent.
  static Future<Unsent> load(AppDatabase db) async {
    final rows =
        await (db.select(db.pendingChangeTable)..where(
              (t) => t.status.isIn([
                PendingStatus.pending.wireName,
                PendingStatus.rejected.wireName,
              ]),
            ))
            .get();
    Set<String> ids(PendingEntity e) => {
      for (final r in rows)
        if (r.entity == e.wireName) r.entityId,
    };

    final visitIds = ids(PendingEntity.visit);
    final stops = ids(PendingEntity.routeStop);
    if (visitIds.isNotEmpty) {
      final visits = await (db.select(
        db.visitTable,
      )..where((t) => t.visitId.isIn(visitIds))).get();
      stops.addAll(visits.map((v) => v.routeStopId));
    }

    final addressIds = ids(PendingEntity.customerAddress);
    final addressOwners = <String>{};
    if (addressIds.isNotEmpty) {
      final addresses = await (db.select(
        db.customerAddressTable,
      )..where((t) => t.addressId.isIn(addressIds))).get();
      addressOwners.addAll(addresses.map((a) => a.customerId));
    }

    return Unsent(
      customers: ids(PendingEntity.customer),
      addresses: addressIds,
      addressOwners: addressOwners,
      stops: stops,
      visits: visitIds,
      // A cancellation moved the truck stock back, like a sale moved it out.
      sales: {
        ...ids(PendingEntity.sale),
        ...ids(PendingEntity.saleCancellation),
      },
    );
  }
}
