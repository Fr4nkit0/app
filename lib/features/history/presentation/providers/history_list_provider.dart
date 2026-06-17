import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/presentation/providers/history_repository_provider.dart';

final historyListProvider = StreamProvider<List<HistoryEntry>>((ref) {
  return ref.watch(historyRepositoryProvider).watchHistory();
});
