import 'package:flutter/foundation.dart';

enum SyncCycleResult {
  success('success'),
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
  });

  /// When the last cycle finished; null before the first one.
  final DateTime? lastCycleAt;
  final SyncCycleResult? lastResult;

  /// Readable cause of the last failed cycle.
  final String? lastError;
  final int pendingCount;
  final int rejectedCount;

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.lastCycleAt == lastCycleAt &&
      other.lastResult == lastResult &&
      other.lastError == lastError &&
      other.pendingCount == pendingCount &&
      other.rejectedCount == rejectedCount;

  @override
  int get hashCode => Object.hash(
    lastCycleAt,
    lastResult,
    lastError,
    pendingCount,
    rejectedCount,
  );
}
