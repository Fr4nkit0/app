import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/data/repositories/mock_customer_repository.dart';

final mockCustomerRepositoryProvider = Provider<MockCustomerRepository>((ref) {
  return MockCustomerRepository();
});

// SWAP POINT — cambiar acá entre mock y drift sin tocar consumers
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return ref.watch(mockCustomerRepositoryProvider);
  // return ref.watch(driftCustomerRepositoryProvider); // reactivar con Drift
});
