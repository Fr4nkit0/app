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
final customerByIdProvider = StreamProvider.family<Customer?, String>((ref, id) {
  final listAsync = ref.watch(customerListProvider);
  return listAsync.when(
    data: (list) => Stream.value(list.where((c) => c.id == id).firstOrNull),
    loading: () => const Stream.empty(),
    error: (e, st) => const Stream.empty(),
  );
});
