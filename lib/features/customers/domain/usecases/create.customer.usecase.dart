import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/customers/domain/models/address_details.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/customers/domain/usecases/add_preference.usecase.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';

class CreateCustomerUseCase {
  final CustomerRepository _customerRepository;
  final TransactionRunner _transaction;

  CreateCustomerUseCase({
    required CustomerRepository customerRepository,
    required TransactionRunner transaction,
  }) : _customerRepository = customerRepository,
       _transaction = transaction;

  /// Stores [customer] with its addresses, preferences and pending changes
  /// in one unit of work and returns it as stored: address fields trimmed
  /// (blank ones as null) and, when none is marked, the first address as the
  /// primary. Throws [ValidationFailure] without a name, an address or a
  /// preference, and for preferences the server would refuse: a window
  /// ending before it starts, or two on the same day and start.
  Future<Customer> execute(Customer customer) async {
    if (customer.name.isEmpty) {
      throw const ValidationFailure('El nombre es requerido');
    }
    if (customer.addresses.isEmpty) {
      throw const ValidationFailure('Debe existir al menos una dirección');
    }
    if (customer.preferences.isEmpty) {
      throw const ValidationFailure('Debe existir al menos una preferencia');
    }
    final windows = <PreferenceDetails>[];
    for (final p in customer.preferences) {
      final window = PreferenceDetails(
        dayOfWeek: p.dayOfWeek,
        start: p.timeWindowStart,
        end: p.timeWindowEnd,
      ).normalized()..validate();
      if (windows.any((w) => w.sameSlot(window.dayOfWeek, window.start))) {
        throw const ValidationFailure(AddPreferenceUseCase.slotTaken);
      }
      windows.add(window);
    }

    final stored = Customer(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      addresses: _withPrimary(customer.addresses.map(_trimmed).toList()),
      preferences: customer.preferences,
    );
    await _transaction(() => _customerRepository.saveCustomer(stored));
    return stored;
  }

  /// Blank fields become null, so this builds the address whole instead of
  /// through [CustomerAddress.copyWith].
  static CustomerAddress _trimmed(CustomerAddress a) {
    final clean = AddressDetails(
      street: a.street,
      neighborhood: a.neighborhood,
      apartment: a.apartment,
      floor: a.floor,
      visualReference: a.visualReference,
    ).trimmed();
    return CustomerAddress(
      id: a.id,
      street: clean.street,
      neighborhood: clean.neighborhood,
      apartment: clean.apartment,
      floor: clean.floor,
      visualReference: clean.visualReference,
      isPrimary: a.isPrimary,
      latitude: a.latitude,
      longitude: a.longitude,
    );
  }

  /// A customer keeps exactly one primary address from the start, so the
  /// device shows it before the server confirms it.
  static List<CustomerAddress> _withPrimary(List<CustomerAddress> addresses) {
    if (addresses.any((a) => a.isPrimary)) return addresses;
    return [addresses.first.copyWith(isPrimary: true), ...addresses.skip(1)];
  }
}
