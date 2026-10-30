import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/customer_address.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer_address.repository.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerAddressRepositoryProvider = Provider<CustomerAddressRepository>(
  (ref) => DriftCustomerAddressRepository(ref.watch(databaseProvider)),
);

/// The customer's enabled addresses, the primary first.
final customerAddressesProvider = StreamProvider.autoDispose
    .family<List<CustomerAddress>, String>(
      (ref, customerId) => ref
          .watch(customerAddressRepositoryProvider)
          .watchForCustomer(customerId),
    );
