import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../domain/models/pending_change.dart';

/// Local rows that still have unsent or rejected changes; the server copy
/// must not overwrite them.
///
/// Customers, addresses and preferences count only their unsent changes: a
/// rejected one was rolled back to the server's values (or deleted), so the
/// server copy applies to it again.
class Unsent {
  const Unsent({
    required this.customers,
    required this.stops,
    required this.visits,
    required this.sales,
    this.addresses = const {},
    this.addressOwners = const {},
    this.preferences = const {},
    this.movements = const {},
    this.rejectedAddresses = const {},
    this.rejectedPreferences = const {},
  });

  final Set<String> customers;
  final Set<String> stops;
  final Set<String> visits;
  final Set<String> sales;

  /// Addresses with their own unsent change.
  final Set<String> addresses;

  /// Addresses whose latest change, or any create, was rejected: the pull
  /// never adopts them as the local copy of a server row (APP-29).
  final Set<String> rejectedAddresses;

  /// Preferences whose latest change, or any create, was rejected: the pull
  /// never adopts them as the local copy of a server row (APP-29).
  final Set<String> rejectedPreferences;

  /// Customers with an unsent address change: a primary switch touches two
  /// addresses, so every address of theirs keeps its local values.
  final Set<String> addressOwners;

  /// Preferences with their own unsent change.
  final Set<String> preferences;

  /// Container movements with their own unsent change.
  final Set<String> movements;

  bool get hasSales => sales.isNotEmpty;

  /// Reads the queue; a stop with an unsent visit counts as unsent.
  static Future<Unsent> load(AppDatabase db) async {
    final rows =
        await (db.select(db.pendingChangeTable)..where(
              (t) =>
                  t.status.isIn([
                    PendingStatus.pending.wireName,
                    PendingStatus.rejected.wireName,
                  ]) |
                  _dismissedRejection(t),
            ))
            .get();
    Set<String> ids(PendingEntity e, {bool unsentOnly = false}) => {
      for (final r in rows)
        if (r.entity == e.wireName &&
            (!unsentOnly || r.status == PendingStatus.pending.wireName))
          r.entityId,
    };
    final latestRejected = await _latestRejected(db);
    Set<String> rejected(PendingEntity e) => {
      for (final (entity, id) in latestRejected)
        if (entity == e.wireName) id,
    };

    final visitIds = ids(PendingEntity.visit);
    final stops = ids(PendingEntity.routeStop);
    if (visitIds.isNotEmpty) {
      final visits = await (db.select(
        db.visitTable,
      )..where((t) => t.visitId.isIn(visitIds))).get();
      stops.addAll(visits.map((v) => v.routeStopId));
    }

    final addressIds = ids(PendingEntity.customerAddress, unsentOnly: true);
    final addressOwners = <String>{};
    if (addressIds.isNotEmpty) {
      final addresses = await (db.select(
        db.customerAddressTable,
      )..where((t) => t.addressId.isIn(addressIds))).get();
      addressOwners.addAll(addresses.map((a) => a.customerId));
    }

    return Unsent(
      customers: ids(PendingEntity.customer, unsentOnly: true),
      addresses: addressIds,
      addressOwners: addressOwners,
      preferences: ids(PendingEntity.customerPreference, unsentOnly: true),
      rejectedAddresses: rejected(PendingEntity.customerAddress),
      rejectedPreferences: rejected(PendingEntity.customerPreference),
      movements: ids(PendingEntity.containerMovement),
      stops: stops,
      visits: visitIds,
      // A cancellation moved the truck stock back, like a sale moved it out.
      sales: {
        ...ids(PendingEntity.sale),
        ...ids(PendingEntity.saleCancellation),
      },
    );
  }

  /// A rejection the driver dismissed: only the notice went away, the
  /// record is still not the server's. A rejection always carries its
  /// reason; a dismissed outdated edit has none.
  static Expression<bool> _dismissedRejection($PendingChangeTableTable t) =>
      t.status.equals(PendingStatus.dismissed.wireName) &
      t.rejectionReason.isNotNull();

  /// The (entity, local id) of every address and preference whose latest
  /// queued change was rejected (dismissed or not), or that had a create
  /// rejected: a change queued while that create was on its way leaves the
  /// row standing, and it is still not the server's.
  static Future<List<(String, String)>> _latestRejected(AppDatabase db) async {
    final rows = await db
        .customSelect(
          'SELECT DISTINCT c.entity, c.entity_id FROM pending_changes c '
          'WHERE (c.status = ?1 OR (c.status = ?5 AND '
          'c.rejection_reason IS NOT NULL)) AND c.entity IN (?2, ?3) '
          'AND (c.action = ?4 OR c.pending_change_id = ('
          'SELECT MAX(l.pending_change_id) FROM pending_changes l '
          'WHERE l.entity = c.entity AND l.entity_id = c.entity_id))',
          variables: [
            Variable.withString(PendingStatus.rejected.wireName),
            Variable.withString(PendingEntity.customerAddress.wireName),
            Variable.withString(PendingEntity.customerPreference.wireName),
            Variable.withString(PendingAction.insert.wireName),
            Variable.withString(PendingStatus.dismissed.wireName),
          ],
          readsFrom: {db.pendingChangeTable},
        )
        .get();
    return [
      for (final r in rows)
        (r.read<String>('entity'), r.read<String>('entity_id')),
    ];
  }
}
