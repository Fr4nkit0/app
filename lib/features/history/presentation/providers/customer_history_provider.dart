import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/history/domain/models/customer_record.dart';
import 'package:app/features/history/presentation/providers/history_repository_provider.dart';

/// The customer's records stored on the device, newest first, for the
/// Historial tab of the profile.
final customerRecordsProvider = StreamProvider.autoDispose
    .family<List<CustomerRecord>, String>(
      (ref, customerId) =>
          ref.watch(historyRepositoryProvider).watchCustomerRecords(customerId),
    );
