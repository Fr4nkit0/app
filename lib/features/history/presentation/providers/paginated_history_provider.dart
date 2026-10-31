import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/history/presentation/providers/history_list_provider.dart';

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
  final HistoryTodaySummary todaySummary;

  const PaginatedHistoryState({
    required this.entries,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.searchQuery = '',
    this.typeFilter,
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
      todaySummary: todaySummary ?? this.todaySummary,
    );
  }
}

class PaginatedHistoryNotifier extends Notifier<PaginatedHistoryState> {
  List<HistoryEntry> _allEntries = [];
  static const int pageSize = 6;

  List<HistoryEntry> _visibleSource(PaginatedHistoryState from) {
    Iterable<HistoryEntry> list = _allEntries;
    final filter = from.typeFilter;
    if (filter != null) {
      list = list.where((e) => e.type == filter);
    }
    final q = from.searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) {
        final name = e.customerName.toLowerCase();
        final desc = e.description.toLowerCase();
        final reason = (e.rejectionReason ?? '').toLowerCase();
        return name.contains(q) || desc.contains(q) || reason.contains(q);
      });
    }
    return list.toList();
  }

  HistoryTodaySummary _computeTodaySummary() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var sales = 0;
    var visits = 0;
    var payments = 0;
    var deliveries = 0;

    for (final e in _allEntries) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      if (day != today) continue;
      switch (e.type) {
        case HistoryEntryType.sale:
          sales++;
        case HistoryEntryType.visit:
          visits++;
        case HistoryEntryType.payment:
          payments++;
        case HistoryEntryType.delivery:
          deliveries++;
        case HistoryEntryType.customer:
        case HistoryEntryType.routeStop:
        case HistoryEntryType.agreement:
          break;
      }
    }

    return HistoryTodaySummary(
      sales: sales,
      visits: visits,
      payments: payments,
      deliveries: deliveries,
    );
  }

  PaginatedHistoryState _sliced(PaginatedHistoryState from) {
    final source = _visibleSource(from);
    final int currentEntriesCount = pageSize * from.currentPage;
    final slicedEntries = source.take(currentEntriesCount).toList();

    return from.copyWith(
      entries: slicedEntries,
      isLoading: false,
      hasReachedMax: slicedEntries.length >= source.length,
      todaySummary: _computeTodaySummary(),
    );
  }

  void _applySlice() => state = _sliced(state);

  @override
  PaginatedHistoryState build() {
    ref.listen<AsyncValue<List<HistoryEntry>>>(historyListProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (allData) {
          _allEntries = allData;
          _applySlice();
        },
        error: (err, stack) {
          state = state.copyWith(isLoading: false);
        },
        loading: () {},
      );
    });

    // What build returns replaces any state set while it runs, so a list
    // already loaded (the screen opened again) is sliced here.
    const initial = PaginatedHistoryState(entries: []);
    final current = ref.read(historyListProvider);
    if (current case AsyncData(:final value)) {
      _allEntries = value;
      return _sliced(initial);
    }
    return current.hasError ? initial.copyWith(isLoading: false) : initial;
  }

  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 1,
      entries: [],
      hasReachedMax: false,
      isLoading: false,
    );
    _applySlice();
  }

  void setTypeFilter(HistoryEntryType? type) {
    state = state.copyWith(
      typeFilter: type,
      clearTypeFilter: type == null,
      currentPage: 1,
      entries: [],
      hasReachedMax: false,
      isLoading: false,
    );
    _applySlice();
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || state.hasReachedMax) return;

    state = state.copyWith(isLoadingMore: true);

    await Future.delayed(const Duration(milliseconds: 400));

    final int nextPage = state.currentPage + 1;
    state = state.copyWith(currentPage: nextPage, isLoadingMore: false);
    _applySlice();
  }

  /// The list follows the queue live, so a refresh only goes back to the
  /// first page; showing the loader again would wait for an emission that
  /// may never come.
  void refresh() {
    state = state.copyWith(currentPage: 1, hasReachedMax: false);
    _applySlice();
  }
}

final paginatedHistoryProvider =
    NotifierProvider.autoDispose<
      PaginatedHistoryNotifier,
      PaginatedHistoryState
    >(() {
      return PaginatedHistoryNotifier();
    });
