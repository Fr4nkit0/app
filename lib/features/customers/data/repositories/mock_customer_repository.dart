import 'dart:async';
import 'package:app/core/utils/resource.dart';
import 'package:app/core/utils/string_utils.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';

class MockCustomerRepository implements CustomerRepository {
  MockCustomerRepository() {
    _customers = _buildInitialCustomers();
    _controller = StreamController<List<Customer>>.broadcast();
    _countController = StreamController<int>.broadcast();
  }

  late List<Customer> _customers;
  late StreamController<List<Customer>> _controller;
  late StreamController<int> _countController;

  List<Customer> get mockCustomers => List.unmodifiable(_customers);

  @override
  Stream<List<Customer>> watchAllCustomers() async* {
    yield _customers;
    yield* _controller.stream;
  }

  @override
  Stream<int> watchCustomerCount() async* {
    yield _customers.length;
    yield* _countController.stream;
  }

  @override
  Future<Resource<Customer?>> getCustomerById(String id) async {
    final customer = _customers.where((c) => c.id == id).firstOrNull;
    return Resource.success(customer);
  }

  @override
  Future<Resource<void>> updateCustomer(Customer customer) async {
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx < 0) {
      return Resource.error(Exception('Customer not found'));
    }
    _customers[idx] = customer;
    _controller.add(_customers);
    return const Resource.success(null);
  }

  @override
  Future<Resource<void>> deleteCustomer(String customerId) async {
    final before = _customers.length;
    _customers.removeWhere((c) => c.id == customerId);
    if (_customers.length < before) {
      _controller.add(_customers);
      _countController.add(_customers.length);
    }
    return const Resource.success(null);
  }

  @override
  Future<List<Customer>> getCustomersPage({
    required int page,
    required int pageSize,
  }) async {
    final offset = page * pageSize;
    final end = offset + pageSize;
    return _customers.sublist(
      offset.clamp(0, _customers.length),
      end.clamp(0, _customers.length),
    );
  }

  @override
  Future<List<Customer>> searchCustomers({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    if (query.isEmpty) {
      final start = page * pageSize;
      if (start >= _customers.length) return [];
      final end = (start + pageSize) < _customers.length
          ? (start + pageSize)
          : _customers.length;
      return _customers.sublist(start, end);
    }

    final filtered = _customers.where((customer) {
      final addressesStr = customer.addresses
          .map((a) => '${a.street ?? ''} ${a.neighborhood ?? ''}')
          .join(' ');
      final target = '${customer.name} ${customer.phone ?? ''} $addressesStr';
      return StringUtils.fuzzyMatch(query, target);
    }).toList();

    final start = page * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize) < filtered.length
        ? (start + pageSize)
        : filtered.length;
    return filtered.sublist(start, end);
  }

  @override
  Future<Resource<void>> saveCustomer(Customer customer) async {
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx >= 0) {
      _customers[idx] = customer;
    } else {
      _customers.add(customer);
    }
    _controller.add(_customers);
    _countController.add(_customers.length);
    return const Resource.success(null);
  }

  static List<Customer> _buildInitialCustomers() => [
    Customer(
      id: 'mock-1',
      name: 'José García',
      phone: '387-555-0101',
      addresses: [
        CustomerAddress(
          id: 'addr-1',
          street: 'Av. San Martín 1300',
          neighborhood: 'Centro',
          isPrimary: true,
        ),
      ],
      preferences: const [],
      productLabels: const ['2 Bidones', '9 Sifones'],
    ),
    Customer(
      id: 'mock-2',
      name: 'Laura Gómez',
      phone: '387-555-0202',
      addresses: [
        CustomerAddress(
          id: 'addr-2',
          street: 'mza 517 C',
          neighborhood: 'Grand Bourg',
          isPrimary: true,
        ),
      ],
      preferences: const [],
      productLabels: const ['1 Bidón'],
    ),
    Customer(
      id: 'mock-3',
      name: "Despensa 'El Sol'",
      phone: '387-555-0303',
      addresses: [
        CustomerAddress(
          id: 'addr-3',
          street: 'mza 77 A',
          neighborhood: 'Limache',
          isPrimary: true,
        ),
      ],
      preferences: const [],
      debtAmount: 6500,
      productLabels: const ['10 Bidones'],
    ),
    Customer(
      id: 'mock-4',
      name: 'Kiosco Don Juan',
      phone: '387-555-0404',
      addresses: [
        CustomerAddress(
          id: 'addr-4',
          street: 'mza 912 D',
          neighborhood: 'Intersindical',
          isPrimary: true,
        ),
      ],
      preferences: const [],
      productLabels: const ['5 Bidones'],
    ),
  ];
}
