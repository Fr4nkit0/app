import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

final pendingChangeRepositoryProvider = Provider<PendingChangeRepository>(
  (ref) => DriftPendingChangeRepository(ref.watch(databaseProvider)),
);

final pendingChangeCountProvider = StreamProvider<int>(
  (ref) => ref.watch(pendingChangeRepositoryProvider).watchPendingCount(),
);

/// Latest queue row of one record, or null when it never entered the queue.
final recordSyncStatusProvider =
    StreamProvider.family<PendingChange?, ({PendingEntity entity, String id})>(
      (ref, key) => ref
          .watch(pendingChangeRepositoryProvider)
          .watchLatestFor(key.entity, key.id),
    );
