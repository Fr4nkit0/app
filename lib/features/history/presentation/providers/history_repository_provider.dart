import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/history/data/repositories/history.repository.dart';
import 'package:app/features/history/data/repositories/mock_history_repository.dart';

final mockHistoryRepositoryProvider =
    Provider<MockHistoryRepository>((ref) => MockHistoryRepository());

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return ref.watch(mockHistoryRepositoryProvider);
});
