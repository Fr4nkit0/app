import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/history/presentation/providers/history_repository_provider.dart';
import 'package:app/features/history/presentation/providers/paginated_history_provider.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

import 'fake_history_repository.dart';

HistoryEntry _sale(int id) => HistoryEntry(
  id: id,
  type: HistoryEntryType.sale,
  customerId: 'cus-1',
  customerName: 'Ana Gómez',
  date: DateTime(2026, 11, 18, 9, id % 60),
  description: 'Venta',
  status: PendingStatus.sent,
);

void main() {
  late FakeHistoryRepository repository;
  late ProviderContainer container;

  setUp(() {
    final entries = [for (var id = 20; id >= 1; id--) _sale(id)];
    repository = FakeHistoryRepository(
      () => Stream.value(entries),
      counts: {
        HistoryEntryType.sale: 3,
        HistoryEntryType.visit: 2,
        HistoryEntryType.payment: 1,
        HistoryEntryType.delivery: 4,
        HistoryEntryType.customer: 9,
      },
    );
    container = ProviderContainer(
      overrides: [historyRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  Future<PaginatedHistoryState> settled() async {
    await Future<void>.delayed(Duration.zero);
    return container.read(paginatedHistoryProvider);
  }

  test('reads one page plus one row from the database, leaving out dismissed '
      'notices', () async {
    container.listen(paginatedHistoryProvider, (_, _) {});
    final state = await settled();

    final (filter, limit) = repository.requests.single;
    expect(limit, PaginatedHistoryNotifier.pageSize + 1);
    expect(filter.hideDismissed, isTrue);
    expect(state.entries.map((e) => e.id), [20, 19, 18, 17, 16, 15]);
    expect(state.hasReachedMax, isFalse);
    expect(state.isLoading, isFalse);
  });

  test('loading more asks the database for the next page at once', () async {
    container.listen(paginatedHistoryProvider, (_, _) {});
    await settled();

    await container.read(paginatedHistoryProvider.notifier).loadMore();
    final state = await settled();

    expect(
      repository.requests.last.$2,
      2 * PaginatedHistoryNotifier.pageSize + 1,
    );
    expect(state.entries, hasLength(12));
    expect(state.isLoadingMore, isFalse);
  });

  test(
    'the filters reach the database query and go back to the first page',
    () async {
      container.listen(paginatedHistoryProvider, (_, _) {});
      await settled();
      final notifier = container.read(paginatedHistoryProvider.notifier);
      await notifier.loadMore();
      await settled();

      notifier.setTypeFilter(HistoryEntryType.payment);
      notifier.toggleIssuesOnly();
      notifier.setSearchQuery('kiosco');
      final state = await settled();

      final (filter, limit) = repository.requests.last;
      expect(filter.type, HistoryEntryType.payment);
      expect(filter.issuesOnly, isTrue);
      expect(filter.search, 'kiosco');
      expect(limit, PaginatedHistoryNotifier.pageSize + 1);
      expect(state.entries, isEmpty);
      expect(state.hasReachedMax, isTrue);
    },
  );

  test('the summary of today comes from the counts of the database', () async {
    container.listen(paginatedHistoryProvider, (_, _) {});
    final summary = (await settled()).todaySummary;

    expect(summary.sales, 3);
    expect(summary.visits, 2);
    expect(summary.payments, 1);
    expect(summary.deliveries, 4);
    expect(summary.totalActivity, 10);
  });
}
