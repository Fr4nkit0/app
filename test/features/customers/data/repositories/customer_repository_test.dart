import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/customer_search.dart';
import 'package:app/features/customers/data/repositories/customer_search_prefilter.dart';

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

    test(
      'saves and gets customer address with null neighborhood (backward compatibility)',
      () async {
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
      },
    );
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

    test(
      'DriftCustomerRepository.searchCustomers matches fuzzy neighborhood and diacritics',
      () async {
        // "1 mao" matches neighborhood "17 de Mayo"
        final results1 = await driftRepo.searchCustomers(
          query: '1 mao',
          page: 0,
          pageSize: 10,
        );
        expect(results1.length, 1);
        expect(results1.first.id, 'c-1');

        // "jose ramon" matches name "José Ramón"
        final results2 = await driftRepo.searchCustomers(
          query: 'jose ramon',
          page: 0,
          pageSize: 10,
        );
        expect(results2.length, 1);
        expect(results2.first.id, 'c-1');

        // "ramon" matches neighborhood "San Ramón" (c-2) and name "José Ramón" (c-1)
        final results3 = await driftRepo.searchCustomers(
          query: 'ramon',
          page: 0,
          pageSize: 10,
        );
        expect(results3.length, 2);
      },
    );

    Future<List<String>> idsFor(String query) async => [
      for (final c in await driftRepo.searchCustomers(
        query: query,
        page: 0,
        pageSize: 10,
      ))
        c.id,
    ];

    test('letters scattered across other words do not match: "franco" finds '
        'Franco only', () async {
      for (final (id, name, street) in [
        ('c-3', 'Café Martínez Belgrano', 'Av. Belgrano 680'),
        ('c-4', 'Fernando Ruiz', 'Córdoba 245'),
        ('c-5', 'Franco Calisaya', 'Pasaje Los Ceibos 245'),
      ]) {
        await driftRepo.saveCustomer(
          Customer(
            id: id,
            name: name,
            addresses: [
              CustomerAddress(
                id: 'a-$id',
                street: street,
                neighborhood: 'Centro',
                isPrimary: true,
              ),
            ],
            preferences: [],
          ),
        );
      }

      expect(await idsFor('franco'), ['c-5']);
    });

    test('name matches come before address matches', () async {
      // c-2 lives in "San Ramón"; c-1 is named "José Ramón".
      expect(await idsFor('ramon'), ['c-1', 'c-2']);
      expect(await idsFor('san'), ['c-2']);
    });

    test('the phone is not searched: digits are the customer number', () async {
      expect(await idsFor('112233'), isEmpty);
      expect(await idsFor('4455'), isEmpty);
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

    test('watching one customer reads only that customer, and a covered one '
        'does not resolve', () async {
      final own = await driftRepo.watchCustomer('own').first;
      expect(own?.name, 'Ramón Propio');
      expect(own?.addresses.single.street, 'Mitre 10');
      expect(await driftRepo.watchCustomer('cover').first, isNull);
      expect(await driftRepo.watchCustomer('missing').first, isNull);
    });

    test('a watched customer emits again when it changes', () async {
      final names = driftRepo.watchCustomer('own').map((c) => c?.name);
      final expectation = expectLater(
        names,
        emitsInOrder(['Ramón Propio', 'Ramón Nuevo']),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await (db.update(db.customerTable)
            ..where((t) => t.customerId.equals('own')))
          .write(const CustomerTableCompanion(name: Value('Ramón Nuevo')));
      await expectation;
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
      for (var i = 1; i <= 20; i++)
        ('k-${i.toString().padLeft(2, '0')}', 'Kiosco'),
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
        await db
            .into(db.customerTable)
            .insert(
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

    test(
      'paging the list yields every customer once, by name then id',
      () async {
        final ids = await pageThrough(
          (page) => driftRepo.getCustomersPage(page: page, pageSize: 10),
        );

        expect(
          ids.toSet(),
          hasLength(ids.length),
          reason: 'duplicated customers',
        );
        expect(ids, expected);
      },
    );

    test('paging an empty search yields the same order as the list', () async {
      final ids = await pageThrough(
        (page) =>
            driftRepo.searchCustomers(query: '', page: page, pageSize: 10),
      );

      expect(ids, expected);
    });

    test('a number finds only that customer, never a phone with the same '
        'digits; a customer without a number is found by name only', () async {
      await (db.update(db.customerTable)
            ..where((t) => t.customerId.equals('b-1')))
          .write(const CustomerTableCompanion(serverId: Value(128)));
      await (db.update(db.customerTable)
            ..where((t) => t.customerId.equals('z-1')))
          .write(const CustomerTableCompanion(phone: Value('3871280000')));

      final byNumber = await driftRepo.searchCustomers(
        query: '#128',
        page: 0,
        pageSize: 10,
      );
      expect(byNumber.map((c) => c.id), ['b-1']);
      expect(byNumber.single.number, 128);

      final digits = await driftRepo.searchCustomers(
        query: '128',
        page: 0,
        pageSize: 10,
      );
      expect(digits.map((c) => c.id), ['b-1']);

      final unsynced = await driftRepo.searchCustomers(
        query: 'agua',
        page: 0,
        pageSize: 10,
      );
      expect(unsynced.single.number, isNull);
    });

    test('paging a search keeps the list order among the matches', () async {
      final ids = await pageThrough(
        (page) => driftRepo.searchCustomers(
          query: 'kiosco',
          page: page,
          pageSize: 10,
        ),
      );

      expect(ids, [
        for (var i = 1; i <= 20; i++) 'k-${i.toString().padLeft(2, '0')}',
      ]);
    });
  });

  group('search narrowed in SQL', () {
    late AppDatabase db;
    late DriftCustomerRepository driftRepo;

    Future<void> seed(
      String id,
      String name, {
      int? number,
      List<(String?, String?)> addresses = const [],
    }) async {
      await driftRepo.saveCustomer(
        Customer(
          id: id,
          name: name,
          addresses: [
            for (final (i, (street, neighborhood)) in addresses.indexed)
              CustomerAddress(
                id: 'a-$id-$i',
                street: street,
                neighborhood: neighborhood,
                isPrimary: i == 0,
              ),
          ],
          preferences: [],
        ),
      );
      if (number != null) {
        await (db.update(db.customerTable)
              ..where((t) => t.customerId.equals(id)))
            .write(CustomerTableCompanion(serverId: Value(number)));
      }
    }

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      driftRepo = DriftCustomerRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<List<String>> idsFor(String query, {int pageSize = 10}) async => [
      for (final c in await driftRepo.searchCustomers(
        query: query,
        page: 0,
        pageSize: pageSize,
      ))
        c.id,
    ];

    test('uppercase accents fold like lowercase ones', () async {
      await seed('c-1', 'ÁLVAREZ ÑUÑEZ');
      await seed('c-2', 'Alberto Núñez');

      expect(await idsFor('alvarez nunez'), ['c-1']);
      expect(await idsFor('ÁLVAREZ'), ['c-1']);
    });

    test('punctuation is ignored: "ohig" finds O\'Higgins', () async {
      await seed('c-1', 'Kiosco Uno', addresses: [("O'Higgins 120", 'Centro')]);
      await seed('c-2', 'Kiosco Dos', addresses: [('Mitre 10', 'Centro')]);

      expect(await idsFor('ohig'), ['c-1']);
      expect(await idsFor('ohiggins 120'), ['c-1']);
    });

    test('SQLite alone narrows to the candidates, folding accents and '
        'punctuation', () async {
      await seed('c-1', 'ÁLVAREZ ÑUÑEZ', addresses: [("O'Higgins 120", null)]);
      await seed(
        'c-2',
        'Kiosco Dos',
        number: 45,
        addresses: [('Mitre', 'Sur')],
      );
      await seed('c-3', 'Bar', addresses: [('Zapiola 9', 'Oculta')]);
      await (db.update(db.customerAddressTable)
            ..where((t) => t.customerId.equals('c-3')))
          .write(const CustomerAddressTableCompanion(enabled: Value(false)));

      Future<List<String>> candidates(String query) async => [
        for (final row
            in await (db.select(db.customerTable)..where(
                  (t) => CustomerSearchPrefilter.candidates(db, t, query),
                ))
                .get())
          row.customerId,
      ]..sort();

      expect(await candidates('alvarez nunez'), ['c-1']);
      expect(await candidates('ohig'), ['c-1']);
      expect(await candidates('#45'), ['c-2']);
      expect(await candidates('sur'), ['c-2']);
      expect(await candidates('zapiola'), isEmpty);
      expect(await candidates('xyzzy'), isEmpty);
    });

    test('every query finds, page by page, exactly what CustomerSearch finds '
        'over the whole list', () async {
      await seed(
        'c-01',
        'José Ramón',
        number: 7,
        addresses: [('Av. Sarmiento 123', '17 de Mayo')],
      );
      await seed(
        'c-02',
        'María Luz',
        number: 12,
        addresses: [('Calle Mitre 456', 'San Ramón')],
      );
      await seed(
        'c-03',
        'ÁLVAREZ ÑUÑEZ',
        number: 128,
        addresses: [("O'Higgins 120", 'Centro')],
      );
      await seed(
        'c-04',
        'Kiosco El Sol',
        addresses: [('Belgrano 1200', 'Villa Mitre')],
      );
      await seed(
        'c-05',
        'Kiosco Ñandú',
        number: 1,
        addresses: [('Pasaje Güemes', 'Barrio Norte')],
      );
      await seed(
        'c-06',
        'Panadería La Espiga',
        addresses: [('Av. 9 de Julio 45', 'Centro')],
      );
      await seed(
        'c-07',
        'Café Martínez',
        number: 45,
        addresses: [('Córdoba 245', 'San Martín')],
      );
      await seed(
        'c-08',
        'Franco Calisaya',
        addresses: [('Pasaje Los Ceibos 245', null)],
      );
      await seed(
        'c-09',
        'Bar Cerrado',
        addresses: [('Zapiola 99', 'Zona Oculta')],
      );
      await (db.update(db.customerAddressTable)
            ..where((t) => t.addressId.equals('a-c-09-0')))
          .write(const CustomerAddressTableCompanion(enabled: Value(false)));
      await seed(
        'c-10',
        'Ramón Cubierto',
        number: 99,
        addresses: [('Mitre 10', 'Centro')],
      );
      await (db.update(db.customerTable)
            ..where((t) => t.customerId.equals('c-10')))
          .write(const CustomerTableCompanion(isCover: Value(true)));
      await seed(
        'c-11',
        'Despensa Doña Rosa',
        addresses: [
          ('Mendoza 1000', 'Tres Cerritos'),
          ('Ruta 9 km 1600', 'Mayo'),
        ],
      );
      await seed(
        'c-12',
        "Ferretería D'Angelo",
        number: 1200,
        addresses: [('San Juan 300', null)],
      );
      await seed('c-13', 'Kiosco', addresses: [(null, null)]);

      final listed = await driftRepo.getCustomersPage(page: 0, pageSize: 1000);
      expect(listed.map((c) => c.id), isNot(contains('c-10')));

      const queries = [
        'jose',
        'kio',
        'kiosco sol',
        'kiosco',
        'mitre',
        'san',
        'san ramon',
        'centro',
        '#128',
        '128',
        '#12',
        '12',
        '1',
        '#1',
        '45',
        '1200',
        '#99',
        'mao',
        'mayo',
        'zapiola',
        'oculta',
        'cerrado',
        'cubierto',
        'ohiggins',
        "o'hig",
        'nandu',
        'guemes',
        'dona rosa',
        'ÁLVAREZ',
        'dangelo',
        'r',
        'xyzzy',
        '#',
        '   ',
      ];
      const pageSize = 3;
      var nonEmpty = 0;
      for (final query in queries) {
        final expected = [
          for (final c in CustomerSearch.filter(query, listed)) c.id,
        ];
        if (expected.isNotEmpty) nonEmpty++;
        final lastPage = expected.length ~/ pageSize + 1;
        for (var page = 0; page <= lastPage; page++) {
          final got = await driftRepo.searchCustomers(
            query: query,
            page: page,
            pageSize: pageSize,
          );
          final start = min(page * pageSize, expected.length);
          final end = min(start + pageSize, expected.length);
          expect(
            got.map((c) => c.id).toList(),
            expected.sublist(start, end),
            reason: 'query "$query", page $page',
          );
        }
      }
      expect(nonEmpty, greaterThan(20), reason: 'the queries must find things');
      expect(await idsFor('zapiola'), isEmpty, reason: 'disabled address');
      expect(await idsFor('cubierto'), isEmpty, reason: 'covered customer');
    });
  });

  test('the app cannot delete a customer: the server rejects every delete', () {
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            f.readAsStringSync().contains('deleteCustomer'))
          f.path,
    ];

    expect(offenders, isEmpty);
  });
}
