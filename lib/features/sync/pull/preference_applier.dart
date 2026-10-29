import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// Customer delivery preferences. A customer with unsent changes keeps its
/// local preferences; new ones are still added.
class PreferenceApplier implements PullApplier {
  PreferenceApplier(this._db);

  final AppDatabase _db;

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

  Future<void> _upsert(Json p, String customerId, PullContext context) async {
    final serverId = p['id'] as int;
    final existing = await (_db.select(
      _db.customerPreferenceTable,
    )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
    final fields = CustomerPreferenceTableCompanion(
      customerId: Value(customerId),
      dayOfWeek: Value(p['day_of_week'] as int),
      timeWindowStart: Value((p['time_window_start'] as String?) ?? '00:00:00'),
      timeWindowEnd: Value(p['time_window_end'] as String?),
      enabled: enabledOf(p),
      serverId: Value(serverId),
    );
    if (existing == null) {
      await _db.into(_db.customerPreferenceTable).insert(fields);
    } else if (!context.unsent.customers.contains(customerId)) {
      await (_db.update(_db.customerPreferenceTable)..where(
            (t) => t.customerPreferenceId.equals(existing.customerPreferenceId),
          ))
          .write(fields);
    }
  }
}
