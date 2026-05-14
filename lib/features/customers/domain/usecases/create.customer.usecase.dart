import 'package:app/features/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';

class CreateCustomerUseCase {
  final CustomerRepository _customerRepository;

  CreateCustomerUseCase({required CustomerRepository customerRepository})
    : _customerRepository = customerRepository;

  Future<Resource<void>> execute(Customer customer) async {
    if (customer.name.isEmpty) {
      return Resource.error(Exception('El nombre es requerido'));
    }
    if (customer.addresses.isEmpty) {
      return Resource.error(Exception('Debe existir al menos una dirección'));
    }
    if (customer.preferences.isEmpty) {
      return Resource.error(Exception('Debe existir al menos una preferencia'));
    }

    return await _customerRepository.saveCustomer(customer);
  }
}
