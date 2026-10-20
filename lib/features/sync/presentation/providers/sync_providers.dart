import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    dio: ref.watch(dioProvider),
    db: ref.watch(databaseProvider),
    sync: ref.watch(syncServiceProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

/// Last cycle and queue counts, updated as the queue changes.
final syncStatusProvider = StreamProvider<SyncStatus>(
  (ref) => ref.watch(syncEngineProvider).watchStatus(),
);

final syncRunningProvider = StreamProvider<bool>(
  (ref) => ref.watch(syncEngineProvider).watchRunning(),
);
