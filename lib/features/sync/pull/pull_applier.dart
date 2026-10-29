import 'package:drift/drift.dart';

import 'server_ids.dart';
import 'unsent.dart';

typedef Json = Map<String, dynamic>;

/// What one download is applied against.
class PullContext {
  const PullContext({required this.unsent, required this.ids});

  /// Local rows the server copy must not overwrite.
  final Unsent unsent;

  /// How the download's server ids map to local ids.
  final ServerIds ids;
}

/// Stores one downloaded entity type.
///
/// The bootstrap and the incremental pull use the same applier, so the id
/// mapping and skip rules of an entity live in one place. Adding a
/// downloaded entity means adding one implementation and registering it in
/// [SyncService]'s applier list, in dependency order.
abstract class PullApplier {
  /// Applies this entity's rows of an incremental pull; [rows] holds every
  /// entity of the download keyed by its wire name.
  Future<void> applyChanges(Map<String, List<Json>> rows, PullContext context);
}

/// Absent when the payload omits it, so the bootstrap keeps local flags.
Value<bool> enabledOf(Json row) => row.containsKey('enabled')
    ? Value(row['enabled'] == true)
    : const Value.absent();

List<Json> jsonList(Object? v) => (v as List<dynamic>? ?? const [])
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList();

double toDouble(Object? v) =>
    v is num ? v.toDouble() : double.parse(v as String);

double? toNullableDouble(Object? v) => v == null ? null : toDouble(v);

String dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
