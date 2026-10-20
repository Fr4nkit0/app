import 'package:app/features/sync/domain/models/pending_change.dart';

import 'history_entry_type.dart';

/// One record the driver made on the street, as stored in the local sync
/// queue, with the outcome the server gave it.
class HistoryEntry {
  /// Position of the record in the sync queue.
  final int id;
  final HistoryEntryType type;
  final String? customerId;
  final String customerName;
  final DateTime date;
  final double? amount;
  final String description;
  final PendingStatus status;

  /// Why the server refused the record; only set when [status] is rejected.
  final String? rejectionReason;

  const HistoryEntry({
    required this.id,
    required this.type,
    required this.customerId,
    required this.customerName,
    required this.date,
    this.amount,
    required this.description,
    required this.status,
    this.rejectionReason,
  });
}
