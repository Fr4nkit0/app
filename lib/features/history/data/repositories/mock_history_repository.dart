import 'dart:async';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/history/data/repositories/history.repository.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';

class MockHistoryRepository implements HistoryRepository {
  MockHistoryRepository() {
    _entries = _buildInitialEntries();
    _controller = StreamController<List<HistoryEntry>>.broadcast();
  }

  late List<HistoryEntry> _entries;
  late StreamController<List<HistoryEntry>> _controller;

  @override
  Stream<List<HistoryEntry>> watchHistory() async* {
    yield List.of(_entries)..sort((a, b) => b.date.compareTo(a.date));
    yield* _controller.stream;
  }

  @override
  Future<void> addEntry(HistoryEntry entry) async {
    _entries.insert(0, entry);
    final sorted = List.of(_entries)..sort((a, b) => b.date.compareTo(a.date));
    _controller.add(sorted);
  }

  static final _mockCustomer1 = Customer(
    id: 'mock-1',
    name: 'José García',
    addresses: [
      CustomerAddress(id: 'addr-1', street: 'Av. San Martín 1234', isPrimary: true),
    ],
    preferences: const [],
    productLabels: const ['2 Bidones', '9 Sifones'],
  );

  static final _mockCustomer3 = Customer(
    id: 'mock-3',
    name: "Despensa 'El Sol'",
    addresses: [
      CustomerAddress(id: 'addr-3', street: 'Mitre 789', isPrimary: true),
    ],
    preferences: const [],
    debtAmount: 6500,
    productLabels: const ['10 Bidones'],
  );

  static List<HistoryEntry> _buildInitialEntries() {
    final now = DateTime.now();
    return [
      HistoryEntry(
        id: 'hist-1',
        type: HistoryEntryType.sale,
        customer: _mockCustomer1,
        date: now.subtract(const Duration(hours: 2)),
        amount: 2400,
        description: '2 Bidones · 9 Sifones',
      ),
      HistoryEntry(
        id: 'hist-2',
        type: HistoryEntryType.visit,
        customer: _mockCustomer3,
        date: now.subtract(const Duration(days: 1, hours: 3)),
        description: 'Solo visita',
      ),
      HistoryEntry(
        id: 'hist-3',
        type: HistoryEntryType.sale,
        customer: _mockCustomer3,
        date: now.subtract(const Duration(days: 2)),
        amount: 8500,
        description: '10 Bidones',
      ),
    ];
  }
}
