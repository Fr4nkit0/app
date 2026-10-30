import 'package:app/core/errors/domain_failure.dart';
import 'package:app/features/customers/domain/models/address_details.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';

/// The delivery addresses of a customer. A customer keeps exactly one
/// enabled primary address. Writes queue their pending change; run them
/// inside a use case's unit of work.
abstract class CustomerAddressRepository {
  /// The customer's enabled addresses: the primary first, then the oldest.
  Stream<List<CustomerAddress>> watchForCustomer(String customerId);

  /// The enabled address [addressId], or null when it is missing or
  /// disabled.
  Future<CustomerAddress?> findEnabled(String addressId);

  /// Adds an address to [customerId] and returns its id. It is the primary
  /// when the customer has none. Throws [NotFoundFailure] when the customer
  /// does not exist.
  Future<String> add(String customerId, AddressDetails details);

  /// Replaces the typed fields of the enabled address [addressId]. Throws
  /// [NotFoundFailure] when it is missing or disabled.
  Future<void> edit(String addressId, AddressDetails details);

  /// Disables [addressId]; the caller checks it is not the primary.
  Future<void> disable(String addressId);

  /// Makes the enabled address [addressId] the primary and unsets the
  /// previous one, queueing both. Throws [NotFoundFailure] when it is
  /// missing or disabled.
  Future<void> setPrimary(String addressId);
}
