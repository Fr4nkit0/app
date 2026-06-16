import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';

final customerCountProvider = StreamProvider<int>((ref) {
  return ref.watch(customerRepositoryProvider).watchCustomerCount();
});

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

  @override
  PaginatedCustomerListState build() {
    return PaginatedCustomerListState();
  }

  /// Loads the next page of customers (handles both normal list and search)
  Future<void> loadNextPage() async {
    if (state.isLoading || state.hasReachedMax) return;

    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(customerRepositoryProvider);
      final List<Customer> newCustomers;

      if (state.searchQuery.isEmpty) {
        // Normal pagination
        newCustomers = await repository.getCustomersPage(
          page: state.currentPage,
          pageSize: _pageSize,
        );
      } else {
        // Search pagination
        newCustomers = await repository.searchCustomers(
          query: state.searchQuery,
          page: state.currentPage,
          pageSize: _pageSize,
        );
      }

      if (newCustomers.length < _pageSize) {
        state = state.copyWith(
          customers: [...state.customers, ...newCustomers],
          currentPage: state.currentPage + 1,
          hasReachedMax: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          customers: [...state.customers, ...newCustomers],
          currentPage: state.currentPage + 1,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Updates search query, resets list, and triggers load
  Future<void> setSearchQuery(String query) async {
    // Reset state for new search
    state = state.copyWith(
      searchQuery: query,
      customers: [],
      currentPage: 0,
      hasReachedMax: false,
      isLoading: false,
    );
    // Load first page of results
    await loadNextPage();
  }

  /// Resets the list and reloads from page 0 (keeps current search query)
  Future<void> refresh() async {
    state = state.copyWith(
      customers: [],
      currentPage: 0,
      hasReachedMax: false,
      isLoading: false,
    );
    await loadNextPage();
  }
}

final paginatedCustomerListProvider =
    NotifierProvider<PaginatedCustomerList, PaginatedCustomerListState>(
      PaginatedCustomerList.new,
    );
