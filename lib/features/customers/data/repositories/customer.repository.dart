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

  /// Disables the customer, which hides it from every list, and queues it.
  /// Throws [NotFoundFailure] when the customer does not exist.
  Future<void> disableCustomer(String customerId);
  Stream<int> watchCustomerCount();

  /// Emits whenever something the customer lists show may have changed:
  /// a customer, its addresses, preferences or balance, or its removal.
  /// Reads no customer; listeners re-read what they show.
  Stream<void> watchChanges();

  /// The listed customer with [id], or null when it does not exist or is
  /// hidden from the lists.
  Stream<Customer?> watchCustomer(String id);
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
