import '../domain/models/sync_status.dart';
import '../sync_engine.dart';
import 'cycle_lease.dart';

/// [SyncEngine] whose cycle also holds a [CycleLease], so a cycle in the
/// foreground app and one in a background isolate never overlap.
///
/// Within one isolate the base engine's single-flight guard still applies: a
/// trigger that fires while a cycle runs joins it.
class LeasedSyncEngine extends SyncEngine {
  LeasedSyncEngine({
    required super.dio,
    required super.db,
    required super.sync,
    required CycleLease lease,
    super.pushers,
    super.now,
  }) : _lease = lease;

  final CycleLease _lease;

  /// Callers of this isolate currently holding the lease.
  int _holders = 0;

  /// Runs one cycle, or joins the one running in this isolate. Returns null
  /// without touching anything when another isolate holds the lease.
  Future<SyncStatus?> runExclusiveCycle() async {
    if (isRunning) return super.runCycle();
    _holders++;
    try {
      if (!await _lease.acquire()) return null;
      return await super.runCycle();
    } finally {
      // Triggers of this isolate share the lease; the last one out frees it.
      if (--_holders == 0) await _lease.release();
    }
  }

  /// Same contract as [SyncEngine.runCycle]: never throws. When another
  /// isolate is mid-cycle it skips and reports the current status.
  @override
  Future<SyncStatus> runCycle() async {
    try {
      return await runExclusiveCycle() ?? await status();
    } catch (_) {
      return status();
    }
  }
}
