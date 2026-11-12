import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';

final customerListProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customerRepositoryProvider).watchAllCustomers();
});

/// Watches a single customer by ID.
/// Reuses the global customer list stream and filters by ID.
final customerByIdProvider = StreamProvider.family<Customer?, String>((
  ref,
  id,
) {
  final listAsync = ref.watch(customerListProvider);
  return listAsync.when(
    data: (list) => Stream.value(list.where((c) => c.id == id).firstOrNull),
    loading: () => const Stream.empty(),
    error: (e, st) => const Stream.empty(),
  );
});

// ─── Pagination ──────────────────────────────────────────────────────────────

class PaginatedCustomerListState {
  final List<Customer> customers;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoading;
  final String searchQuery;

  PaginatedCustomerListState({
    this.customers = const [],
    this.currentPage = 0,
    this.hasReachedMax = false,
    this.isLoading = false,
    this.searchQuery = '',
  });

  PaginatedCustomerListState copyWith({
    List<Customer>? customers,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoading,
    String? searchQuery,
  }) {
    return PaginatedCustomerListState(
      customers: customers ?? this.customers,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class PaginatedCustomerList extends Notifier<PaginatedCustomerListState> {
  static const int _pageSize = 10;

  /// Bumped by every read that replaces the shown list (a reload, a new
  /// search, a refresh). A read that finishes after a newer replacement
  /// started is discarded: appending a page computed against the previous
  /// list repeats customers (or drops the reloaded ones).
  int _generation = 0;

  /// Pages the user asked to see, including the one on its way. A reload
  /// reads this deep so the page it discards is not lost.
  int _requestedPages = 0;

  @override
  PaginatedCustomerListState build() {
    // Drift's live query emits whenever a sync or an edit touches the
    // customers, so the loaded pages are reloaded instead of going stale.
    ref.listen(customerListProvider, (_, next) {
      if (next.hasValue) reload();
    });
    return PaginatedCustomerListState();
  }

  Future<List<Customer>> _read({
    required String query,
    required int page,
    required int pageSize,
  }) {
    final repository = ref.read(customerRepositoryProvider);
    return query.isEmpty
        ? repository.getCustomersPage(page: page, pageSize: pageSize)
        : repository.searchCustomers(
            query: query,
            page: page,
            pageSize: pageSize,
          );
  }

  /// Reloads as many customers as are already shown or on their way,
  /// keeping the search and the scroll depth.
  ///
  /// It supersedes a page still loading, and marks the list as loading so
  /// no page is asked for against the list it is about to replace.
  Future<void> reload() async {
    final generation = ++_generation;
    final pages = _requestedPages < 1 ? 1 : _requestedPages;
    _requestedPages = pages;
    state = state.copyWith(isLoading: true);
    try {
      final customers = await _read(
        query: state.searchQuery,
        page: 0,
        pageSize: _pageSize * pages,
      );
      if (generation != _generation) return;
      state = state.copyWith(
        customers: customers,
        currentPage: pages,
        hasReachedMax: customers.length < _pageSize * pages,
        isLoading: false,
      );
    } catch (_) {
      // Keep what is shown; the next change or a manual refresh retries.
      if (generation == _generation) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Loads the next page of customers (handles both normal list and search)
  Future<void> loadNextPage() async {
    if (state.isLoading || state.hasReachedMax) return;

    final generation = _generation;
    final page = state.currentPage;
    _requestedPages = page + 1;
    state = state.copyWith(isLoading: true);

    try {
      final newCustomers = await _read(
        query: state.searchQuery,
        page: page,
        pageSize: _pageSize,
      );
      // A reload or a new search replaced the list meanwhile; it owns the
      // loading flag and already covers this page.
      if (generation != _generation) return;

      // Offsets shift when a customer is added or removed between two
      // pages; the reload that change triggers fixes the list, and until
      // then a customer is never shown twice.
      final shown = {for (final c in state.customers) c.id};
      state = state.copyWith(
        customers: [
          ...state.customers,
          for (final c in newCustomers)
            if (!shown.contains(c.id)) c,
        ],
        currentPage: page + 1,
        hasReachedMax: newCustomers.length < _pageSize,
        isLoading: false,
      );
    } catch (e) {
      if (generation == _generation) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Updates search query, resets list, and triggers load
  Future<void> setSearchQuery(String query) async {
    _reset(searchQuery: query);
    // Load first page of results
    await loadNextPage();
  }

  /// Resets the list and reloads from page 0 (keeps current search query)
  Future<void> refresh() async {
    _reset();
    await loadNextPage();
  }

  /// Empties the list and supersedes any read still on its way.
  void _reset({String? searchQuery}) {
    _generation++;
    _requestedPages = 0;
    state = state.copyWith(
      searchQuery: searchQuery,
      customers: [],
      currentPage: 0,
      hasReachedMax: false,
      isLoading: false,
    );
  }
}

final paginatedCustomerListProvider =
    NotifierProvider<PaginatedCustomerList, PaginatedCustomerListState>(
      PaginatedCustomerList.new,
    );
