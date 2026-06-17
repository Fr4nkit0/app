import 'package:app/features/history/domain/models/history_entry.dart';

abstract class HistoryRepository {
  Stream<List<HistoryEntry>> watchHistory();
  Future<void> addEntry(HistoryEntry entry);
  Future<void> syncAllPending();
}
