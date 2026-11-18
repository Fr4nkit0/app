import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/history/domain/models/customer_record.dart';
import 'package:app/features/history/presentation/providers/history_repository_provider.dart';

/// How many records of a customer the Historial tab shows per page.
const customerRecordsPageSize = 20;

/// The newest [CustomerRecordsQuery.limit] records of a customer stored on
/// the device, newest first, plus one more when older records exist, so the
/// Historial tab of the profile knows whether to offer more.
final customerRecordsProvider = StreamProvider.autoDispose
    .family<List<CustomerRecord>, CustomerRecordsQuery>(
      (ref, query) => ref
          .watch(historyRepositoryProvider)
          .watchCustomerRecords(query.customerId, limit: query.limit + 1),
    );

typedef CustomerRecordsQuery = ({String customerId, int limit});
