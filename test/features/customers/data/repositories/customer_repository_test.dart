import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';

void main() {
  group('DriftCustomerRepository Mapping', () {
    late AppDatabase db;
    late DriftCustomerRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftCustomerRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('saves and gets customer address with neighborhood', () async {
      final customer = Customer(
        id: 'cust-1',
        name: 'Carlos Gomez',
        phone: '11223344',
        addresses: [
          CustomerAddress(
            id: 'addr-1',
            street: 'Av. Belgrano 1200',
            neighborhood: 'Centro',
            isPrimary: true,
          ),
        ],
        preferences: [],
      );

      await repo.saveCustomer(customer);

      final fetchedCustomer = await repo.getCustomerById('cust-1');
      expect(fetchedCustomer, isNotNull);
      expect(fetchedCustomer!.addresses.first.neighborhood, 'Centro');
    });

    test('saves and gets customer address with null neighborhood (backward compatibility)', () async {
      final customer = Customer(
        id: 'cust-2',
        name: 'Maria Plaza',
        addresses: [
          CustomerAddress(
            id: 'addr-2',
            street: 'Av. Sarmiento 300',
            neighborhood: null,
            isPrimary: true,
          ),
        ],
        preferences: [],
      );

      await repo.saveCustomer(customer);

      final fetchedCustomer = await repo.getCustomerById('cust-2');
      expect(fetchedCustomer, isNotNull);
      expect(fetchedCustomer!.addresses.first.neighborhood, isNull);
    });
  });

  group('Customer Repository Fuzzy Search', () {
    late AppDatabase db;
    late DriftCustomerRepository driftRepo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      driftRepo = DriftCustomerRepository(db);

      // Seed Drift repository with some test customers
      final customer1 = Customer(
        id: 'c-1',
        name: 'José Ramón',
        phone: '112233',
        addresses: [
          CustomerAddress(
            id: 'a-1',
            street: 'Av. Sarmiento 123',
            neighborhood: '17 de Mayo',
            isPrimary: true,
          ),
        ],
        preferences: [],
      );
      final customer2 = Customer(
        id: 'c-2',
        name: 'María Luz',
        phone: '445566',
        addresses: [
          CustomerAddress(
            id: 'a-2',
            street: 'Calle Mitre 456',
            neighborhood: 'San Ramón',
            isPrimary: true,
          ),
        ],
        preferences: [],
      );
      await driftRepo.saveCustomer(customer1);
      await driftRepo.saveCustomer(customer2);
    });

    tearDown(() async {
      await db.close();
    });

    test('DriftCustomerRepository.searchCustomers matches fuzzy neighborhood and diacritics', () async {
      // "1 mao" matches neighborhood "17 de Mayo"
      final results1 = await driftRepo.searchCustomers(query: '1 mao', page: 0, pageSize: 10);
      expect(results1.length, 1);
      expect(results1.first.id, 'c-1');

      // "jose ramon" matches name "José Ramón"
      final results2 = await driftRepo.searchCustomers(query: 'jose ramon', page: 0, pageSize: 10);
      expect(results2.length, 1);
      expect(results2.first.id, 'c-1');

      // "ramon" matches neighborhood "San Ramón" (c-2) and name "José Ramón" (c-1)
      final results3 = await driftRepo.searchCustomers(query: 'ramon', page: 0, pageSize: 10);
      expect(results3.length, 2);
    });
  });

  group('covered customers', () {
    late AppDatabase db;
    late DriftCustomerRepository driftRepo;

    Customer customer(String id, String name) => Customer(
      id: id,
      name: name,
      phone: '387-$id',
      addresses: [
        CustomerAddress(id: 'a-$id', street: 'Mitre 10', isPrimary: true),
      ],
      preferences: [],
    );

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      driftRepo = DriftCustomerRepository(db);
      await driftRepo.saveCustomer(customer('own', 'Ramón Propio'));
      await driftRepo.saveCustomer(customer('cover', 'Ramón Cubierto'));
      await (db.update(db.customerTable)
            ..where((t) => t.customerId.equals('cover')))
          .write(const CustomerTableCompanion(isCover: Value(true)));
    });

    tearDown(() async {
      await db.close();
    });

    List<String> ids(List<Customer> list) => [for (final c in list) c.id];

    test('are left out of the Clientes page', () async {
      final page = await driftRepo.getCustomersPage(page: 0, pageSize: 10);
      expect(ids(page), ['own']);
    });

    test('are left out of the search, with and without a query', () async {
      expect(
        ids(
          await driftRepo.searchCustomers(
            query: 'ramon',
            page: 0,
            pageSize: 10,
          ),
        ),
        ['own'],
      );
      expect(
        ids(await driftRepo.searchCustomers(query: '', page: 0, pageSize: 10)),
        ['own'],
      );
    });

    test('are left out of the watched list and the count', () async {
      expect(ids(await driftRepo.watchAllCustomers().first), ['own']);
      expect(await driftRepo.watchCustomerCount().first, 1);
    });

    test('an own customer (marker false) stays listed', () async {
      await (db.update(db.customerTable)
            ..where((t) => t.customerId.equals('cover')))
          .write(const CustomerTableCompanion(isCover: Value(false)));
      final page = await driftRepo.getCustomersPage(page: 0, pageSize: 10);
      expect(ids(page)..sort(), ['cover', 'own']);
    });
  });

  group('Clientes paging order', () {
    late AppDatabase db;
    late DriftCustomerRepository driftRepo;

    /// 25 customers, most of them sharing a name, stored in no particular
    /// order (the pull does not download them sorted).
    final seeded = <(String, String)>[
      for (var i = 1; i <= 20; i++) ('k-${i.toString().padLeft(2, '0')}', 'Kiosco'),
      ('a-1', 'almacén Don Pepe'),
      ('b-1', 'Bar Central'),
      ('z-1', 'Zapatería'),
      ('a-2', 'Agua Viva'),
      ('k-cover', 'Kiosco'),
    ];

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      driftRepo = DriftCustomerRepository(db);
      final shuffled = [...seeded]..shuffle(Random(3));
      for (final (id, name) in shuffled) {
        await db.into(db.customerTable).insert(
              CustomerTableCompanion.insert(customerId: Value(id), name: name),
            );
      }
      await (db.update(db.customerTable)
            ..where((t) => t.customerId.equals('k-cover')))
          .write(const CustomerTableCompanion(isCover: Value(true)));
    });

    tearDown(() async {
      await db.close();
    });

    /// Name (ignoring case), then id: customers sharing a name keep a fixed
    /// place between reads.
    final expected = [
      'a-2', // Agua Viva
      'a-1', // almacén Don Pepe
      'b-1', // Bar Central
      for (var i = 1; i <= 20; i++) 'k-${i.toString().padLeft(2, '0')}',
      'z-1', // Zapatería
    ];

    Future<List<String>> pageThrough(
      Future<List<Customer>> Function(int page) read,
    ) async {
      final ids = <String>[];
      for (var page = 0; ; page++) {
        final customers = await read(page);
        ids.addAll(customers.map((c) => c.id));
        if (customers.length < 10) return ids;
      }
    }

    test('paging the list yields every customer once, by name then id', () async {
      final ids = await pageThrough(
        (page) => driftRepo.getCustomersPage(page: page, pageSize: 10),
      );

      expect(ids.toSet(), hasLength(ids.length), reason: 'duplicated customers');
      expect(ids, expected);
    });

    test('paging an empty search yields the same order as the list', () async {
      final ids = await pageThrough(
        (page) => driftRepo.searchCustomers(query: '', page: page, pageSize: 10),
      );

      expect(ids, expected);
    });

    test('paging a search keeps the list order among the matches', () async {
      final ids = await pageThrough(
        (page) =>
            driftRepo.searchCustomers(query: 'kiosco', page: page, pageSize: 10),
      );

      expect(ids, [for (var i = 1; i <= 20; i++) 'k-${i.toString().padLeft(2, '0')}']);
    });
  });

  test('the app cannot delete a customer: the server rejects every delete', () {
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart') && f.readAsStringSync().contains('deleteCustomer'))
          f.path,
    ];

    expect(offenders, isEmpty);
  });
}
