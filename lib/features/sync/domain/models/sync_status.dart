import 'package:flutter/foundation.dart';

enum SyncCycleResult {
  success('success'),

  /// The cycle could not reach the server: the changes stay on the phone.
  offline('offline'),
  failure('failure');

  const SyncCycleResult(this.wireName);

  final String wireName;

  static SyncCycleResult? fromWire(String? value) {
    for (final r in values) {
      if (r.wireName == value) return r;
    }
    return null;
  }
}

/// What the driver needs to trust the sync: how the last cycle ended and
/// what is still waiting in the queue.
@immutable
class SyncStatus {
  const SyncStatus({
    this.lastCycleAt,
    this.lastResult,
    this.lastError,
    this.pendingCount = 0,
    this.rejectedCount = 0,
    this.heldCount = 0,
    this.heldStopIds = const {},
  });

  /// When the last cycle finished; null before the first one.
  final DateTime? lastCycleAt;
  final SyncCycleResult? lastResult;

  /// Readable cause of the last failed cycle.
  final String? lastError;
  final int pendingCount;
  final int rejectedCount;

  /// Pending changes linked to an open visit: they wait for it to close
  /// instead of travelling, and are part of [pendingCount].
  final int heldCount;

  /// Stops whose open visit holds those changes.
  final Set<String> heldStopIds;

  /// Pending changes that travel on the next cycle.
  int get readyCount => pendingCount - heldCount;

  /// Why the held changes wait, or null when none does.
  String? get heldLabel => heldCount == 0
      ? null
      : '$heldCount ${heldCount == 1 ? 'espera' : 'esperan'} cierre de visita';

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.lastCycleAt == lastCycleAt &&
      other.lastResult == lastResult &&
      other.lastError == lastError &&
      other.pendingCount == pendingCount &&
      other.rejectedCount == rejectedCount &&
      other.heldCount == heldCount &&
      setEquals(other.heldStopIds, heldStopIds);

  @override
  int get hashCode => Object.hash(
    lastCycleAt,
    lastResult,
    lastError,
    pendingCount,
    rejectedCount,
    heldCount,
    Object.hashAllUnordered(heldStopIds),
  );
}
