import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';

final pendingChangeRepositoryProvider = Provider<PendingChangeRepository>(
  (ref) => DriftPendingChangeRepository(ref.watch(databaseProvider)),
);

final pendingChangeCountProvider = StreamProvider<int>(
  (ref) => ref.watch(pendingChangeRepositoryProvider).watchPendingCount(),
);
