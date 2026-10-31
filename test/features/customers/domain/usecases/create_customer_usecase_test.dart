import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/domain/usecases/create.customer.usecase.dart';

/// Stores the customer and queues it, then fails.
class _FailingAfterWriteRepository extends DriftCustomerRepository {
  _FailingAfterWriteRepository(super.db);

  @override
  Future<void> saveCustomer(Customer customer) async {
    await super.saveCustomer(customer);
    throw Exception('disk full');
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  CreateCustomerUseCase useCase([CustomerRepository? repo]) =>
      CreateCustomerUseCase(
        customerRepository: repo ?? DriftCustomerRepository(db),
        transaction: driftTransactionRunner(db),
      );

  Customer customer({
    String name = 'Kiosco Norte',
    List<CustomerAddress>? addresses,
    List<CustomerPreference>? preferences,
  }) => Customer(
    id: 'cust-1',
    name: name,
    addresses:
        addresses ?? [CustomerAddress(id: 'addr-1', street: 'Belgrano 1200')],
    preferences:
        preferences ??
        [
          CustomerPreference(
            id: 'pref-1',
            dayOfWeek: 1,
            timeWindowStart: '09:00',
          ),
        ],
  );

  Future<void> expectNothingStored() async {
    expect(await db.select(db.customerTable).get(), isEmpty);
    expect(await db.select(db.customerAddressTable).get(), isEmpty);
    expect(await db.select(db.customerPreferenceTable).get(), isEmpty);
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
  }

  test(
    'stores the customer with its address and preference and queues it',
    () async {
      await useCase().execute(customer());

      expect(
        (await db.select(db.customerTable).getSingle()).name,
        'Kiosco Norte',
      );
      expect(await db.select(db.customerAddressTable).get(), hasLength(1));
      expect(await db.select(db.customerPreferenceTable).get(), hasLength(1));
      // The customer, then its preference.
      expect(await db.select(db.pendingChangeTable).get(), hasLength(2));
    },
  );

  Future<List<dynamic>> pushedAddresses() async {
    final change = await (db.select(
      db.pendingChangeTable,
    )..where((t) => t.entity.equals('customer'))).getSingle();
    return (jsonDecode(change.payload!) as Map<String, dynamic>)['addresses']
        as List<dynamic>;
  }

  test('the only address of a new customer is its primary', () async {
    final stored = await useCase().execute(customer());

    final row = await db.select(db.customerAddressTable).getSingle();
    expect(row.isPrimary, isTrue);
    expect((await pushedAddresses()).single['isPrimary'], isTrue);
    expect(stored.addresses.single.isPrimary, isTrue);
  });

  test('without a primary the first address becomes it', () async {
    await useCase().execute(
      customer(
        addresses: [
          CustomerAddress(id: 'addr-1', street: 'Belgrano 1200'),
          CustomerAddress(id: 'addr-2', street: 'Mitre 50'),
        ],
      ),
    );

    final rows = {
      for (final r in await db.select(db.customerAddressTable).get())
        r.addressId: r.isPrimary,
    };
    expect(rows, {'addr-1': true, 'addr-2': false});
    expect(
      [for (final a in await pushedAddresses()) a['isPrimary']],
      [true, false],
    );
  });

  test('a marked primary is kept', () async {
    await useCase().execute(
      customer(
        addresses: [
          CustomerAddress(id: 'addr-1', street: 'Belgrano 1200'),
          CustomerAddress(id: 'addr-2', street: 'Mitre 50', isPrimary: true),
        ],
      ),
    );

    final rows = {
      for (final r in await db.select(db.customerAddressTable).get())
        r.addressId: r.isPrimary,
    };
    expect(rows, {'addr-1': false, 'addr-2': true});
  });

  test(
    'address fields are stored and pushed trimmed, without the newline Enter leaves',
    () async {
      await useCase().execute(
        customer(
          addresses: [
            CustomerAddress(
              id: 'addr-1',
              street: ' Belgrano 1200 ',
              floor: '  ',
              visualReference: 'Portón negro\n',
            ),
          ],
        ),
      );

      final row = await db.select(db.customerAddressTable).getSingle();
      expect(row.street, 'Belgrano 1200');
      expect(row.floor, isNull);
      expect(row.visualReference, 'Portón negro');
      final pushed = (await pushedAddresses()).single;
      expect(pushed['visualReference'], 'Portón negro');
      expect(pushed['street'], 'Belgrano 1200');
    },
  );

  for (final (name, invalid, message)
      in <(String, Customer Function(), String)>[
        ('an empty name', () => customer(name: ''), 'El nombre es requerido'),
        (
          'no address',
          () => customer(addresses: []),
          'Debe existir al menos una dirección',
        ),
        (
          'no preference',
          () => customer(preferences: []),
          'Debe existir al menos una preferencia',
        ),
      ]) {
    test('$name throws a ValidationFailure and stores nothing', () async {
      await expectLater(
        useCase().execute(invalid()),
        throwsA(
          isA<ValidationFailure>().having((f) => f.message, 'message', message),
        ),
      );
      await expectNothingStored();
    });
  }

  test('a failing write leaves no customer and no pending change', () async {
    await expectLater(
      useCase(_FailingAfterWriteRepository(db)).execute(customer()),
      throwsA(isA<StorageFailure>()),
    );
    await expectNothingStored();
  });
}
