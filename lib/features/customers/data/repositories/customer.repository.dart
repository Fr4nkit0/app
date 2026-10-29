import 'package:app/core/errors/domain_failure.dart';
import 'package:app/features/customers/domain/models/customer.dart';

abstract class CustomerRepository {
  // Writes queue their pending change; run them inside a use case's unit
  // of work.
  Future<void> saveCustomer(Customer customer);
  Future<Customer?> getCustomerById(String id);

  /// Throws [NotFoundFailure] when the customer does not exist.
  Future<void> updateCustomer(Customer customer);
  Stream<int> watchCustomerCount();
  Stream<List<Customer>> watchAllCustomers();
  Future<List<Customer>> getCustomersPage({
    required int page,
    required int pageSize,
  });
  Future<List<Customer>> searchCustomers({
    required String query,
    required int page,
    required int pageSize,
  });
}
