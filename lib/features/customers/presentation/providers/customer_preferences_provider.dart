import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/customer_preference.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer_preference.repository.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerPreferenceRepositoryProvider =
    Provider<CustomerPreferenceRepository>(
      (ref) => DriftCustomerPreferenceRepository(ref.watch(databaseProvider)),
    );

/// The customer's enabled delivery preferences, by day and start.
final customerPreferencesProvider = StreamProvider.autoDispose
    .family<List<CustomerPreference>, String>(
      (ref, customerId) => ref
          .watch(customerPreferenceRepositoryProvider)
          .watchForCustomer(customerId),
    );
