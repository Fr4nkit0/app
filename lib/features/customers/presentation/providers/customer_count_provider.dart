import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';

final customerCountProvider = StreamProvider<int>((ref) {
  return ref.watch(customerRepositoryProvider).watchCustomerCount();
});

final customerListProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customerRepositoryProvider).watchAllCustomers();
});
