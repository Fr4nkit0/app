import 'package:app/features/customers/domain/models/customer.dart';
import 'history_entry_type.dart';

class HistoryEntry {
  final String id;
  final HistoryEntryType type;
  final Customer customer;
  final DateTime date;
  final double? amount;
  final String description;
  final bool isSynced;
  final List<String> tags;

  const HistoryEntry({
    required this.id,
    required this.type,
    required this.customer,
    required this.date,
    this.amount,
    required this.description,
    this.isSynced = true,
    this.tags = const [],
  });
}
