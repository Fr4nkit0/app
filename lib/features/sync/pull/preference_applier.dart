import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../../customers/domain/models/preference_details.dart';
import '../data/repositories/server_shadow.dart';
import 'pull_applier.dart';

/// Customer delivery preferences, disabled ones included. Days are stored
/// as the server sends them (0 = Sunday ... 6 = Saturday) and times as
/// `HH:mm`.
class PreferenceApplier implements PullApplier {
  PreferenceApplier(this._db) : _shadow = ServerShadow(_db);

  final AppDatabase _db;
  final ServerShadow _shadow;

  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final p in rows['customer_preferences'] ?? const <Json>[]) {
      final customerId = await context.ids.customer(p['customer_id'] as int?);
      if (customerId == null) continue;
      await _upsert(p, customerId, context);
    }
  }

  /// Stores the [preferences] of [customerId], as the bootstrap nests them.
  Future<void> applyForCustomer(
    String customerId,
    List<Json> preferences,
    PullContext context,
  ) async {
    for (final p in preferences) {
      await _upsert(p, customerId, context);
    }
  }

  /// A server preference is matched by its server id, then by its client
  /// uuid (the local id it was pushed with), then by an unlinked local
  /// preference in the same day and start: the server keeps one per slot,
  /// so that one is the same preference created on both sides. A local
  /// preference whose latest change was rejected is never that one.
  ///
  /// A preference with its own unsent change, or of a customer with unsent
  /// changes, keeps its local values; it only gets linked to its server id.
  /// The server values it skipped are kept for a rollback of its change.
  Future<void> _upsert(Json p, String customerId, PullContext context) async {
    final serverId = p['id'] as int;
    final clientUuid = p['client_uuid'] as String?;
    final fields = CustomerPreferenceTableCompanion(
      customerId: Value(customerId),
      dayOfWeek: Value(p['day_of_week'] as int),
      timeWindowStart: Value(
        PreferenceDetails.hhmm(p['time_window_start'] as String?) ??
            PreferenceDetails.noStart,
      ),
      timeWindowEnd: Value(
        PreferenceDetails.hhmm(p['time_window_end'] as String?),
      ),
      enabled: enabledOf(p),
      serverId: Value(serverId),
    );
    final existing =
        await (_db.select(
          _db.customerPreferenceTable,
        )..where((t) => t.serverId.equals(serverId))).getSingleOrNull() ??
        (clientUuid == null
            ? null
            : await (_db.select(_db.customerPreferenceTable)
                    ..where((t) => t.customerPreferenceId.equals(clientUuid)))
                  .getSingleOrNull()) ??
        await _unlinkedInSlot(customerId, fields, context);
    if (existing == null) {
      await _db
          .into(_db.customerPreferenceTable)
          .insert(
            fields.copyWith(
              customerPreferenceId: clientUuid == null
                  ? const Value.absent()
                  : Value(clientUuid),
            ),
          );
      return;
    }
    final ownChange = context.unsent.preferences.contains(
      existing.customerPreferenceId,
    );
    final keepLocal =
        context.unsent.customers.contains(customerId) || ownChange;
    if (ownChange) {
      await _shadow.storePulledPreference(
        existing.customerPreferenceId,
        fields,
      );
    }
    await (_db.update(_db.customerPreferenceTable)..where(
          (t) => t.customerPreferenceId.equals(existing.customerPreferenceId),
        ))
        .write(
          keepLocal
              ? CustomerPreferenceTableCompanion(serverId: Value(serverId))
              : fields,
        );
  }

  Future<CustomerPreferenceTableData?> _unlinkedInSlot(
    String customerId,
    CustomerPreferenceTableCompanion fields,
    PullContext context,
  ) async {
    final slot = PreferenceDetails(
      dayOfWeek: fields.dayOfWeek.value,
      start: fields.timeWindowStart.value,
    );
    final candidates =
        await (_db.select(_db.customerPreferenceTable)..where(
              (t) =>
                  t.customerId.equals(customerId) &
                  t.dayOfWeek.equals(slot.dayOfWeek) &
                  t.serverId.isNull() &
                  t.customerPreferenceId.isNotIn(
                    context.unsent.rejectedPreferences,
                  ),
            ))
            .get();
    for (final c in candidates) {
      if (slot.sameSlot(c.dayOfWeek, c.timeWindowStart)) return c;
    }
    return null;
  }
}
