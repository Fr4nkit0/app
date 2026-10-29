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
      expect(await db.select(db.pendingChangeTable).get(), hasLength(1));
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
