import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';

/// Reactive stream of total customer count.
/// Emits a new value every time the [CustomerTable] is modified.
final customerCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(driftCustomerRepositoryProvider);
  return repository.watchCustomerCount();
});

/// Reactive stream of all customers for the list screen.
final customerListProvider = StreamProvider<List<Customer>>((ref) {
  final repository = ref.watch(driftCustomerRepositoryProvider);
  return repository.watchAllCustomers();
});
