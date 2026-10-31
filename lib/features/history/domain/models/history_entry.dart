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

  /// The values the server refused, by wire name; only set on a rejection
  /// the device recorded them for.
  final Map<String, dynamic>? rejectedValues;

  /// What the device did with the local row of a rejected record.
  final RejectionRollback? rollback;

  /// The wire fields an edit changed, when the queue recorded them.
  final List<String>? changedFields;

  /// A server answer the driver should read: a rejection or an edit
  /// dropped as older (APP-26, APP-30).
  bool get isIssue =>
      status == PendingStatus.rejected || status == PendingStatus.outdated;

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
    this.rejectedValues,
    this.rollback,
    this.changedFields,
  });
}
