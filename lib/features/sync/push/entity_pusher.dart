import 'package:flutter/foundation.dart';

import '../domain/models/pending_change.dart';

typedef Json = Map<String, dynamic>;

/// One server record built from one or more queued changes of the same
/// local record.
@immutable
class PushRecord {
  const PushRecord({
    required this.uuid,
    required this.body,
    required this.changeIds,
    String? localId,
  }) : localId = localId ?? uuid;

  /// Local row this record comes from; the [uuid] unless one row travels
  /// as several records.
  final String localId;

  /// Client uuid: the server's idempotency key for this record.
  final String uuid;

  /// The record as the server expects it (snake_case, server ids).
  final Json body;

  /// Queue entries this record settles once the server answers.
  final List<int> changeIds;
}

/// A queued change that cannot be expressed as a server record.
@immutable
class LocalRejection {
  const LocalRejection(this.changeIds, this.reason);

  final List<int> changeIds;
  final String reason;
}

@immutable
class PushPlan {
  const PushPlan({
    this.records = const [],
    this.rejections = const [],
    this.settled = const [],
  });

  /// One queued change may produce several records; it is sent only once
  /// every record it produced was accepted.
  final List<PushRecord> records;
  final List<LocalRejection> rejections;

  /// Queue entries the server learns through other records (a stop status
  /// travels with its visit), so they are settled without being sent.
  final List<int> settled;
}

/// Translates one entity type of the pending queue into its list of the
/// push body and applies the server ids it gets back.
///
/// Adding an entity type to the push means adding one implementation and
/// registering it in [SyncEngine]'s pusher list, in dependency order.
abstract class EntityPusher {
  /// Queue entity this pusher handles.
  PendingEntity get entity;

  /// Key of this entity's list in the push request and response.
  String get wireKey;

  /// Builds the records for [changes], oldest first.
  Future<PushPlan> plan(List<PendingChange> changes);

  /// Links the local record to the id the server assigned it.
  Future<void> applyAccepted(PushRecord record, int serverId);
}
