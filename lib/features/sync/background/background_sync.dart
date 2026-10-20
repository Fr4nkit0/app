import '../domain/models/sync_status.dart';
import 'leased_sync_engine.dart';

/// How one background run ended.
enum BackgroundSyncOutcome {
  /// The cycle ran and succeeded.
  synced,

  /// No network: nothing was attempted.
  offline,

  /// Nobody is signed in: nothing was attempted.
  signedOut,

  /// Another isolate (usually the open app) was mid-cycle.
  busy,

  /// The cycle ran and failed; the engine recorded why in the sync status.
  failed,
}

/// Background job entry point, free of platform channels so it runs under
/// plain tests.
///
/// Runs the same engine cycle as the foreground app, guarded by the
/// cross-isolate lease. Never throws: a failure is reported as an outcome
/// and left to the next window. The engine itself only moves pending changes
/// on a server answer and saves the cursor with the applied pull, so a
/// failure leaves both as they were.
Future<BackgroundSyncOutcome> runBackgroundSync({
  required LeasedSyncEngine engine,
  required Future<bool> Function() isOnline,
  Future<bool> Function()? isSignedIn,
}) async {
  try {
    if (isSignedIn != null && !await isSignedIn()) {
      return BackgroundSyncOutcome.signedOut;
    }
  } catch (_) {
    return BackgroundSyncOutcome.signedOut;
  }
  try {
    if (!await isOnline()) return BackgroundSyncOutcome.offline;
  } catch (_) {
    return BackgroundSyncOutcome.offline;
  }
  try {
    final status = await engine.runExclusiveCycle();
    if (status == null) return BackgroundSyncOutcome.busy;
    return status.lastResult == SyncCycleResult.success
        ? BackgroundSyncOutcome.synced
        : BackgroundSyncOutcome.failed;
  } catch (_) {
    return BackgroundSyncOutcome.failed;
  }
}

/// Value the platform job reports back. Always true: every outcome is
/// "done until the next periodic window". Reporting false would make the
/// scheduler retry with backoff on top of the periodic schedule, piling runs
/// up exactly when there is no network or the server is down.
bool backgroundTaskResult(BackgroundSyncOutcome outcome) => true;
