import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

  test('the app cannot delete a customer: the server rejects every delete', () {
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart') && f.readAsStringSync().contains('deleteCustomer'))
          f.path,
    ];

    expect(offenders, isEmpty);
  });
}
