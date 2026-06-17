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

  @override
  Future<void> syncAllPending() async {
    _entries = _entries.map((entry) {
      if (!entry.isSynced) {
        return HistoryEntry(
          id: entry.id,
          type: entry.type,
          customer: entry.customer,
          date: entry.date,
          amount: entry.amount,
          description: entry.description,
          isSynced: true,
          tags: entry.tags,
        );
      }
      return entry;
    }).toList();
    final sorted = List.of(_entries)..sort((a, b) => b.date.compareTo(a.date));
    _controller.add(sorted);
  }

  static final _mockLuisMorales = Customer(
    id: 'mock-luis',
    name: 'Luis Morales',
    addresses: [
      CustomerAddress(id: 'addr-luis', street: 'Pellegrini 456', isPrimary: true),
    ],
    preferences: const [],
    productLabels: const ['2 Bidones'],
  );

  static final _mockMinimercadoMitre = Customer(
    id: 'mock-mitre',
    name: 'Minimercado Mitre',
    addresses: [
      CustomerAddress(id: 'addr-mitre', street: 'Mitre 789', isPrimary: true),
    ],
    preferences: const [],
    productLabels: const ['20L'],
  );

  static final _mockCarniceriaFamilia = Customer(
    id: 'mock-familia',
    name: 'Carnicería Familia',
    addresses: [
      CustomerAddress(id: 'addr-familia', street: 'Av. San Martín 1234', isPrimary: true),
    ],
    preferences: const [],
    productLabels: const [],
  );

  static final _mockDespensaPaco = Customer(
    id: 'mock-paco',
    name: 'Despensa Paco',
    addresses: [
      CustomerAddress(id: 'addr-paco', street: 'Belgrano 1011', isPrimary: true),
    ],
    preferences: const [],
    productLabels: const ['Bidones 12L'],
  );

  static final _mockSupermercadoChino = Customer(
    id: 'mock-chino',
    name: 'Supermercado Chino',
    addresses: [
      CustomerAddress(id: 'addr-chino', street: 'Moreno 1420', isPrimary: true),
    ],
    preferences: const [],
    productLabels: const ['Bidones 12L'],
  );

  static final _mockPanaderiaDelSol = Customer(
    id: 'mock-panaderia',
    name: 'Panadería del Sol',
    addresses: [
      CustomerAddress(id: 'addr-panaderia', street: 'Urquiza 550', isPrimary: true),
    ],
    preferences: const [],
    productLabels: const [],
  );

  static final _mockKioscoLaPlaza = Customer(
    id: 'mock-kiosco',
    name: 'Kiosco La Plaza',
    addresses: [
      CustomerAddress(id: 'addr-kiosco', street: 'Rivadavia 202', isPrimary: true),
    ],
    preferences: const [],
    productLabels: const ['20L'],
  );

  static final _mockVerduleriaTito = Customer(
    id: 'mock-verduleria',
    name: 'Verdulería Tito',
    addresses: [
      CustomerAddress(id: 'addr-verduleria', street: 'Sarmiento 890', isPrimary: true),
    ],
    preferences: const [],
    productLabels: const [],
  );

  static List<HistoryEntry> _buildInitialEntries() {
    final now = DateTime.now();
    return [
      HistoryEntry(
        id: 'hist-1',
        type: HistoryEntryType.visit,
        customer: _mockLuisMorales,
        date: DateTime(now.year, now.month, now.day, 14, 20),
        description: 'Visita iniciada',
        isSynced: true,
      ),
      HistoryEntry(
        id: 'hist-2',
        type: HistoryEntryType.sale,
        customer: _mockMinimercadoMitre,
        date: DateTime(now.year, now.month, now.day, 13, 45),
        description: 'Venta registrada',
        isSynced: true,
        tags: const ['2 x 20L', 'MIXTO'],
      ),
      HistoryEntry(
        id: 'hist-3',
        type: HistoryEntryType.payment,
        customer: _mockCarniceriaFamilia,
        date: DateTime(now.year, now.month, now.day, 13, 10),
        amount: 26000,
        description: 'Cobro realizado',
        isSynced: false,
      ),
      HistoryEntry(
        id: 'hist-4',
        type: HistoryEntryType.delivery,
        customer: _mockDespensaPaco,
        date: DateTime(now.year, now.month, now.day, 12, 50),
        description: 'Entrega de bidones',
        isSynced: false,
        tags: const ['10 bidones 12L'],
      ),
      HistoryEntry(
        id: 'hist-5',
        type: HistoryEntryType.sale,
        customer: _mockSupermercadoChino,
        date: DateTime(now.year, now.month, now.day, 11, 30),
        description: 'Venta registrada',
        isSynced: true,
        tags: const ['5 x 12L'],
      ),
      HistoryEntry(
        id: 'hist-6',
        type: HistoryEntryType.payment,
        customer: _mockPanaderiaDelSol,
        date: DateTime(now.year, now.month, now.day, 10, 15),
        amount: 12500,
        description: 'Cobro realizado',
        isSynced: true,
      ),
      // Ayer
      HistoryEntry(
        id: 'hist-7',
        type: HistoryEntryType.visit,
        customer: _mockLuisMorales,
        date: now.subtract(const Duration(days: 1)).copyWith(hour: 17, minute: 0),
        description: 'Visita iniciada',
        isSynced: true,
      ),
      HistoryEntry(
        id: 'hist-8',
        type: HistoryEntryType.sale,
        customer: _mockKioscoLaPlaza,
        date: now.subtract(const Duration(days: 1)).copyWith(hour: 15, minute: 45),
        description: 'Venta registrada',
        isSynced: true,
        tags: const ['1 x 20L'],
      ),
      HistoryEntry(
        id: 'hist-9',
        type: HistoryEntryType.delivery,
        customer: _mockVerduleriaTito,
        date: now.subtract(const Duration(days: 1)).copyWith(hour: 14, minute: 30),
        description: 'Entrega de bidones',
        isSynced: true,
        tags: const ['3 bidones 20L'],
      ),
      HistoryEntry(
        id: 'hist-10',
        type: HistoryEntryType.payment,
        customer: _mockLuisMorales,
        date: now.subtract(const Duration(days: 1)).copyWith(hour: 11, minute: 15),
        amount: 8400,
        description: 'Cobro realizado',
        isSynced: true,
      ),
      // Hace 2 días
      HistoryEntry(
        id: 'hist-11',
        type: HistoryEntryType.sale,
        customer: _mockDespensaPaco,
        date: now.subtract(const Duration(days: 2)).copyWith(hour: 16, minute: 45),
        description: 'Venta registrada',
        isSynced: true,
        tags: const ['12 x 12L'],
      ),
      HistoryEntry(
        id: 'hist-12',
        type: HistoryEntryType.payment,
        customer: _mockLuisMorales,
        date: now.subtract(const Duration(days: 2)).copyWith(hour: 15, minute: 30),
        amount: 9800,
        description: 'Cobro realizado',
        isSynced: true,
      ),
      HistoryEntry(
        id: 'hist-13',
        type: HistoryEntryType.delivery,
        customer: _mockCarniceriaFamilia,
        date: now.subtract(const Duration(days: 2)).copyWith(hour: 14, minute: 15),
        description: 'Entrega de bidones',
        isSynced: true,
        tags: const ['4 bidones 20L'],
      ),
      HistoryEntry(
        id: 'hist-14',
        type: HistoryEntryType.visit,
        customer: _mockSupermercadoChino,
        date: now.subtract(const Duration(days: 2)).copyWith(hour: 10, minute: 50),
        description: 'Visita iniciada',
        isSynced: true,
      ),
      // Hace 3 días
      HistoryEntry(
        id: 'hist-15',
        type: HistoryEntryType.delivery,
        customer: _mockPanaderiaDelSol,
        date: now.subtract(const Duration(days: 3)).copyWith(hour: 17, minute: 15),
        description: 'Entrega de bidones',
        isSynced: true,
        tags: const ['6 bidones 12L'],
      ),
      HistoryEntry(
        id: 'hist-16',
        type: HistoryEntryType.sale,
        customer: _mockLuisMorales,
        date: now.subtract(const Duration(days: 3)).copyWith(hour: 15, minute: 0),
        description: 'Venta registrada',
        isSynced: true,
        tags: const ['2 x 20L'],
      ),
      // Hace 4 días
      HistoryEntry(
        id: 'hist-17',
        type: HistoryEntryType.payment,
        customer: _mockLuisMorales,
        date: now.subtract(const Duration(days: 4)).copyWith(hour: 13, minute: 45),
        amount: 6500,
        description: 'Cobro realizado',
        isSynced: true,
      ),
      HistoryEntry(
        id: 'hist-18',
        type: HistoryEntryType.visit,
        customer: _mockDespensaPaco,
        date: now.subtract(const Duration(days: 4)).copyWith(hour: 11, minute: 0),
        description: 'Visita iniciada',
        isSynced: true,
      ),
    ];
  }
}
