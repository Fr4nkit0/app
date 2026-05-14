import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';

abstract class CustomerRepository {
  Future<Resource<void>> saveCustomer(Customer customer);
  Stream<int> watchCustomerCount();
  Stream<List<Customer>> watchAllCustomers();
}
