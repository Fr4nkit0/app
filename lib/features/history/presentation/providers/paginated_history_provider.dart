import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/presentation/providers/history_list_provider.dart';

class PaginatedHistoryState {
  final List<HistoryEntry> entries;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final int currentPage;

  const PaginatedHistoryState({
    required this.entries,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  PaginatedHistoryState copyWith({
    List<HistoryEntry>? entries,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return PaginatedHistoryState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class PaginatedHistoryNotifier extends Notifier<PaginatedHistoryState> {
  List<HistoryEntry> _allEntries = [];
  static const int pageSize = 6;

  @override
  PaginatedHistoryState build() {
    // Listen to historyListProvider reactively to sync updates
    ref.listen<AsyncValue<List<HistoryEntry>>>(historyListProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (allData) {
          _allEntries = allData;
          final int currentEntriesCount = pageSize * state.currentPage;
          final slicedEntries = allData.take(currentEntriesCount).toList();

          state = state.copyWith(
            entries: slicedEntries,
            isLoading: false,
            hasReachedMax: slicedEntries.length >= allData.length,
          );
        },
        error: (err, stack) {
          state = state.copyWith(isLoading: false);
        },
        loading: () {
          // Do not force full rebuild during micro-loading
        },
      );
    }, fireImmediately: true);

    return const PaginatedHistoryState(entries: [], isLoading: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || state.hasReachedMax) return;

    state = state.copyWith(isLoadingMore: true);

    // Simulate network delay for loading more history entries
    await Future.delayed(const Duration(milliseconds: 1200));

    final int nextPage = state.currentPage + 1;
    final int nextEntriesCount = pageSize * nextPage;
    final slicedEntries = _allEntries.take(nextEntriesCount).toList();

    state = state.copyWith(
      entries: slicedEntries,
      currentPage: nextPage,
      isLoadingMore: false,
      hasReachedMax: slicedEntries.length >= _allEntries.length,
    );
  }

  void refresh() {
    state = const PaginatedHistoryState(entries: [], isLoading: true);
    ref.invalidateSelf();
  }
}

final paginatedHistoryProvider =
    NotifierProvider.autoDispose<
      PaginatedHistoryNotifier,
      PaginatedHistoryState
    >(() {
      return PaginatedHistoryNotifier();
    });
