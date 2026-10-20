import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/background/background_sync_task.dart';
import 'package:app/features/sync/background/cycle_lease.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';

void main() {
  test(
    'the app engine from the providers respects a cycle held by the background job',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          apiBaseUrlProvider.overrideWithValue('https://unreachable.test'),
          leasedSyncEngineOverride(owner: foregroundLeaseOwner),
        ],
      );
      addTearDown(container.dispose);
      expect(
        await CycleLease(db, owner: backgroundLeaseOwner).acquire(),
        isTrue,
      );

      final status = await container.read(syncEngineProvider).runCycle();

      // Skipped: no cycle ran, so none was recorded (an attempt against the
      // unreachable host would have recorded a failure).
      expect(status.lastResult, isNull);
    },
  );
}
