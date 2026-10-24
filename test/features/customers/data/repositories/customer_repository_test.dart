import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/data/repositories/mock_customer_repository.dart';
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

      final saveResult = await repo.saveCustomer(customer);
      expect(saveResult, isA<Success<void>>());

      final getResult = await repo.getCustomerById('cust-1');
      expect(getResult, isA<Success<Customer?>>());
      final fetchedCustomer = (getResult as Success<Customer?>).value;
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

      final saveResult = await repo.saveCustomer(customer);
      expect(saveResult, isA<Success<void>>());

      final getResult = await repo.getCustomerById('cust-2');
      expect(getResult, isA<Success<Customer?>>());
      final fetchedCustomer = (getResult as Success<Customer?>).value;
      expect(fetchedCustomer, isNotNull);
      expect(fetchedCustomer!.addresses.first.neighborhood, isNull);
    });
  });

  group('MockCustomerRepository Seeding', () {
    test('mock customers have valid neighborhoods', () async {
      final repo = MockCustomerRepository();
      final customersResult = await repo.getCustomersPage(page: 0, pageSize: 10);
      
      expect(customersResult.isNotEmpty, isTrue);
      for (final customer in customersResult) {
        for (final address in customer.addresses) {
          // Verify that initially seeded customers have non-empty neighborhood values
          expect(address.neighborhood, isNotNull);
          expect(address.neighborhood!.isNotEmpty, isTrue);
        }
      }
    });
  });

  group('Customer Repository Fuzzy Search', () {
    late AppDatabase db;
    late DriftCustomerRepository driftRepo;
    late MockCustomerRepository mockRepo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      driftRepo = DriftCustomerRepository(db);
      mockRepo = MockCustomerRepository();

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

    test('MockCustomerRepository.searchCustomers matches fuzzy neighborhood and diacritics', () async {
      // "jose" matches "José García"
      final results1 = await mockRepo.searchCustomers(query: 'jose', page: 0, pageSize: 10);
      expect(results1.length, 1);
      expect(results1.first.name, 'José García');

      // "garcia centro" matches José García (Av. San Martín 1300, Centro)
      final results2 = await mockRepo.searchCustomers(query: 'garcia centro', page: 0, pageSize: 10);
      expect(results2.length, 1);
      expect(results2.first.name, 'José García');
    });
  });
}
