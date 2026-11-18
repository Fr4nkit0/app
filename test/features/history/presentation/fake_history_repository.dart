import 'package:app/features/history/data/repositories/history.repository.dart';
import 'package:app/features/history/domain/models/customer_record.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/history/domain/models/history_filter.dart';

/// History over an in-memory list of entries, filtered and limited the way
/// the database does it.
class FakeHistoryRepository implements HistoryRepository {
  FakeHistoryRepository(this._source, {this.counts = const {}});

  /// Every entry of the queue, newest first, at each change.
  final Stream<List<HistoryEntry>> Function() _source;
  final Map<HistoryEntryType, int> counts;

  /// The filter and limit of each watch, in order.
  final requests = <(HistoryFilter, int?)>[];

  @override
  Stream<List<HistoryEntry>> watchHistory({
    HistoryFilter filter = const HistoryFilter(),
    int? limit,
  }) {
    requests.add((filter, limit));
    return _source().map((all) {
      final listed = all.where(filter.matches);
      return (limit == null ? listed : listed.take(limit)).toList();
    });
  }

  @override
  Stream<Map<HistoryEntryType, int>> watchCountsByType({
    required DateTime Function() since,
  }) => Stream.value(counts);

  @override
  Stream<List<CustomerRecord>> watchCustomerRecords(
    String customerId, {
    int? limit,
  }) => throw UnimplementedError();
}
