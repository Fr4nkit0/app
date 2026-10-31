import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../../customers/domain/models/preference_details.dart';
import '../data/repositories/server_shadow.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Delivery preferences added or changed from the wizard or the profile.
///
/// Like addresses, every change of the same preference collapses into one
/// record rebuilt from the current local row, in the order the preferences
/// were first queued. The customer record carries no preferences, so a
/// known customer never waits for them.
///
/// A rejected preference goes back to the server's values (the server row
/// the answer carries, or the last ones known), or is deleted when the
/// server never stored it: the pull then brings the server's preference in
/// that slot as a row of its own.
class CustomerPreferencePusher implements EntityPusher, RejectionAware {
  CustomerPreferencePusher(this._db);

  /// A preference is never deleted on the device; a change whose row is
  /// gone cannot be sent.
  static const missingPreference =
      'La preferencia ya no existe en el teléfono.';

  final AppDatabase _db;

  @override
  PendingEntity get entity => PendingEntity.customerPreference;

  @override
  String get wireKey => 'customer_preferences';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final idsByPreference = <String, List<int>>{};
    for (final c in changes) {
      idsByPreference.putIfAbsent(c.entityId, () => []).add(c.id);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    for (final MapEntry(key: preferenceId, value: changeIds)
        in idsByPreference.entries) {
      final preference =
          await (_db.select(_db.customerPreferenceTable)
                ..where((t) => t.customerPreferenceId.equals(preferenceId)))
              .getSingleOrNull();
      if (preference == null) {
        rejections.add(LocalRejection(changeIds, missingPreference));
        continue;
      }
      records.add(
        PushRecord(
          uuid: preferenceId,
          body: await _body(preference),
          changeIds: changeIds,
        ),
      );
    }
    return PushPlan(records: records, rejections: rejections);
  }

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    await (_db.update(_db.customerPreferenceTable)
          ..where((t) => t.customerPreferenceId.equals(record.uuid)))
        .write(CustomerPreferenceTableCompanion(serverId: Value(serverId)));
  }

  @override
  Future<void> applyRejected(String localId, {Json? current}) async {
    final preference = await (_db.select(
      _db.customerPreferenceTable,
    )..where((t) => t.customerPreferenceId.equals(localId))).getSingleOrNull();
    if (preference == null) return;
    await ServerShadow(_db).rollBackRejected(
      entity,
      localId,
      refused: _values(preference),
      stored: preference.serverId != null,
      current: current,
      delete: () async {
        await (_db.delete(
          _db.customerPreferenceTable,
        )..where((t) => t.customerPreferenceId.equals(localId))).go();
        return true;
      },
    );
  }

  Future<Json> _body(CustomerPreferenceTableData preference) async => {
    'uuid': preference.customerPreferenceId,
    'server_id': ?preference.serverId,
    ...await customerReference(_db, preference.customerId),
    ..._values(preference),
    'modified_at': preference.lastModifiedDate.toUtc().toIso8601String(),
  };

  static Json _values(CustomerPreferenceTableData preference) {
    final start = PreferenceDetails.hhmm(preference.timeWindowStart);
    return {
      'day_of_week': preference.dayOfWeek,
      // The server may hold a preference without a start; it is stored
      // locally as the no-start time and goes back as null.
      'time_window_start': start == PreferenceDetails.noStart ? null : start,
      'time_window_end': PreferenceDetails.hhmm(preference.timeWindowEnd),
      'enabled': preference.enabled,
    };
  }
}
