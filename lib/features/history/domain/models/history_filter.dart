import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// Which records of the history are listed.
class HistoryFilter {
  const HistoryFilter({
    this.type,
    this.issuesOnly = false,
    this.search = '',
    this.hideDismissed = false,
  });

  /// Only records of this type; every type when null.
  final HistoryEntryType? type;

  /// Only the rejected and dropped records ([HistoryEntry.isIssue]).
  final bool issuesOnly;

  /// Text the customer name, description or rejection reason contains,
  /// ignoring case; blank lists every record.
  final String search;

  /// Leaves out the notices the driver dismissed.
  final bool hideDismissed;

  String get _needle => search.trim().toLowerCase();

  bool get hasSearch => _needle.isNotEmpty;

  /// Whether [entry] is listed under this filter.
  bool matches(HistoryEntry entry) {
    if (hideDismissed && entry.status == PendingStatus.dismissed) return false;
    if (issuesOnly && !entry.isIssue) return false;
    if (type != null && entry.type != type) return false;
    return matchesSearch(entry);
  }

  /// Whether [entry] contains the [search] text.
  bool matchesSearch(HistoryEntry entry) {
    final needle = _needle;
    if (needle.isEmpty) return true;
    return entry.customerName.toLowerCase().contains(needle) ||
        entry.description.toLowerCase().contains(needle) ||
        (entry.rejectionReason ?? '').toLowerCase().contains(needle);
  }
}
