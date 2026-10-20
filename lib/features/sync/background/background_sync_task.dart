import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:workmanager/workmanager.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/services/database.helper.dart';
import '../presentation/providers/sync_providers.dart';
import '../sync_service.dart';
import 'background_sync.dart';
import 'cycle_lease.dart';
import 'leased_sync_engine.dart';

/// Unique name of the periodic job. On iOS it is also the BGTaskScheduler
/// identifier, so it must be listed in `BGTaskSchedulerPermittedIdentifiers`
/// in `ios/Runner/Info.plist`.
const backgroundSyncTaskName = 'com.marilin.app.backgroundSync';

/// Lease owners. Fixed names: a restarted process takes back its own lease
/// instead of waiting for it to expire.
const foregroundLeaseOwner = 'foreground';
const backgroundLeaseOwner = 'background';

/// Replaces the engine with one that holds the cross-isolate lease. The
/// foreground app and the background job must both use it, or the guard
/// only protects one side.
Override leasedSyncEngineOverride({required String owner}) =>
    syncEngineProvider.overrideWith((ref) {
      final db = ref.watch(databaseProvider);
      final engine = LeasedSyncEngine(
        dio: ref.watch(dioProvider),
        db: db,
        sync: ref.watch(syncServiceProvider),
        lease: CycleLease(db, owner: owner),
      );
      ref.onDispose(engine.dispose);
      return engine;
    });

/// Registers the periodic best-effort job. Android runs it at most every
/// 15 minutes and only with network; iOS decides when, if ever, to run it.
Future<void> scheduleBackgroundSync() async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    backgroundSyncTaskName,
    backgroundSyncTaskName,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

/// Entry point of the background isolate; only forwards to
/// [runBackgroundSyncTask].
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return backgroundTaskResult(await runBackgroundSyncTask());
  });
}

/// Builds the app's own wiring (database file, Dio with the stored token,
/// engine) in this isolate and runs one guarded cycle.
Future<BackgroundSyncOutcome> runBackgroundSyncTask() async {
  final container = ProviderContainer(
    overrides: [leasedSyncEngineOverride(owner: backgroundLeaseOwner)],
  );
  try {
    final storage = container.read(secureStorageProvider);
    return await runBackgroundSync(
      engine: container.read(syncEngineProvider) as LeasedSyncEngine,
      isSignedIn: () async => await storage.read(key: 'auth_token') != null,
      isOnline: () async {
        final results = await Connectivity().checkConnectivity();
        return results.any((r) => r != ConnectivityResult.none);
      },
    );
  } catch (_) {
    // Missing configuration or a plugin failing to start: wait for the
    // next window.
    return BackgroundSyncOutcome.failed;
  } finally {
    container.dispose();
  }
}
