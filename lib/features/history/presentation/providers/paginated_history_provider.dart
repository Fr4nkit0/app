import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/history/data/repositories/history.repository.dart';
import 'package:app/features/history/domain/models/history_filter.dart';
import 'package:app/features/history/presentation/providers/history_repository_provider.dart';

class HistoryTodaySummary {
  const HistoryTodaySummary({
    this.sales = 0,
    this.visits = 0,
    this.payments = 0,
    this.deliveries = 0,
  });

  final int sales;
  final int visits;
  final int payments;
  final int deliveries;

  int get totalActivity => sales + visits + payments + deliveries;
}

class PaginatedHistoryState {
  final List<HistoryEntry> entries;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final int currentPage;
  final String searchQuery;
  final HistoryEntryType? typeFilter;

  /// Only the rejected and dropped records ([HistoryEntry.isIssue]).
  final bool issuesOnly;
  final HistoryTodaySummary todaySummary;

  const PaginatedHistoryState({
    required this.entries,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.searchQuery = '',
    this.typeFilter,
    this.issuesOnly = false,
    this.todaySummary = const HistoryTodaySummary(),
  });

  PaginatedHistoryState copyWith({
    List<HistoryEntry>? entries,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedMax,
    int? currentPage,
    String? searchQuery,
    HistoryEntryType? typeFilter,
    bool clearTypeFilter = false,
    bool? issuesOnly,
    HistoryTodaySummary? todaySummary,
  }) {
    return PaginatedHistoryState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      issuesOnly: issuesOnly ?? this.issuesOnly,
      todaySummary: todaySummary ?? this.todaySummary,
    );
  }
}

class PaginatedHistoryNotifier extends Notifier<PaginatedHistoryState> {
  static const int pageSize = 6;

  late HistoryRepository _repository;
  StreamSubscription<List<HistoryEntry>>? _entriesSubscription;

  /// Whether the current subscription has not emitted yet; the previous
  /// entries stay on screen meanwhile and no further page is requested.
  bool _awaitingEntries = false;

  @override
  PaginatedHistoryState build() {
    _repository = ref.watch(historyRepositoryProvider);

    final countsSubscription = _repository
        .watchCountsByType(since: _startOfToday)
        .listen(
          (counts) => state = state.copyWith(todaySummary: _summaryOf(counts)),
          onError: (Object _, StackTrace _) {},
        );
    ref.onDispose(() {
      countsSubscription.cancel();
      _entriesSubscription?.cancel();
      _entriesSubscription = null;
    });

    const initial = PaginatedHistoryState(entries: []);
    // Emissions are asynchronous, so the state built here is in place
    // before the first one arrives.
    _subscribe(initial);
    return initial;
  }

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static HistoryTodaySummary _summaryOf(Map<HistoryEntryType, int> counts) =>
      HistoryTodaySummary(
        sales: counts[HistoryEntryType.sale] ?? 0,
        visits: counts[HistoryEntryType.visit] ?? 0,
        payments: counts[HistoryEntryType.payment] ?? 0,
        deliveries: counts[HistoryEntryType.delivery] ?? 0,
      );

  /// Watches the newest records [from] lists, one more than the pages shown
  /// so the end of the list is known, replacing the previous watch.
  void _subscribe(PaginatedHistoryState from) {
    _entriesSubscription?.cancel();
    _awaitingEntries = true;
    final shown = pageSize * from.currentPage;
    final filter = HistoryFilter(
      type: from.typeFilter,
      issuesOnly: from.issuesOnly,
      search: from.searchQuery,
      hideDismissed: true,
    );
    _entriesSubscription = _repository
        .watchHistory(filter: filter, limit: shown + 1)
        .listen(
          (emitted) {
            _awaitingEntries = false;
            state = state.copyWith(
              entries: emitted.take(shown).toList(),
              hasReachedMax: emitted.length <= shown,
              isLoading: false,
              isLoadingMore: false,
            );
          },
          onError: (Object _, StackTrace _) {
            _awaitingEntries = false;
            state = state.copyWith(isLoading: false, isLoadingMore: false);
          },
        );
  }

  void _restart(PaginatedHistoryState next) {
    state = next;
    _subscribe(next);
  }

  void setSearchQuery(String query) {
    _restart(state.copyWith(searchQuery: query, currentPage: 1));
  }

  void setTypeFilter(HistoryEntryType? type) {
    _restart(
      state.copyWith(
        typeFilter: type,
        clearTypeFilter: type == null,
        currentPage: 1,
      ),
    );
  }

  void toggleIssuesOnly() {
    _restart(state.copyWith(issuesOnly: !state.issuesOnly, currentPage: 1));
  }

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        state.hasReachedMax ||
        _awaitingEntries) {
      return;
    }
    _restart(
      state.copyWith(currentPage: state.currentPage + 1, isLoadingMore: true),
    );
  }

  /// The list follows the queue live, so a refresh only goes back to the
  /// first page; the entries shown stay until the new watch emits.
  void refresh() {
    _restart(state.copyWith(currentPage: 1));
  }
}

final paginatedHistoryProvider =
    NotifierProvider.autoDispose<
      PaginatedHistoryNotifier,
      PaginatedHistoryState
    >(() {
      return PaginatedHistoryNotifier();
    });
