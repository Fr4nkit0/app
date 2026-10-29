import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return ref.watch(driftCustomerRepositoryProvider);
});
