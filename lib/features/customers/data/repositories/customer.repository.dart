import 'package:app/core/errors/domain_failure.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer_edit.dart';

abstract class CustomerRepository {
  // Writes queue their pending change; run them inside a use case's unit
  // of work.
  Future<void> saveCustomer(Customer customer);
  Future<Customer?> getCustomerById(String id);

  /// Writes the name, phone and delivery address of [edit] and queues the
  /// customer. Throws [NotFoundFailure] when the customer does not exist.
  Future<void> editCustomer(CustomerEdit edit);
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
