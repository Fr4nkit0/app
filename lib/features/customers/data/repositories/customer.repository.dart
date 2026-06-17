import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';

abstract class CustomerRepository {
  Future<Resource<void>> saveCustomer(Customer customer);
  Future<Resource<Customer?>> getCustomerById(String id);
  Future<Resource<void>> updateCustomer(Customer customer);
  Future<Resource<void>> deleteCustomer(String customerId);
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
