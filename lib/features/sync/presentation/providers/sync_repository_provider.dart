import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/sync.repository.dart';

final syncRepositoryProvider = Provider<SyncRepository>(
  (ref) => DriftSyncRepository(ref.watch(databaseProvider)),
);
