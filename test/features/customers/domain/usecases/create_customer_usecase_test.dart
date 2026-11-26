import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/balance_corrections/data/repositories/balance_correction.repository.dart';
import 'package:app/features/balance_corrections/domain/models/balance_correction.dart';
import 'package:app/features/balance_corrections/domain/usecases/correct_balance.usecase.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/domain/models/opening_balance.dart';
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

/// Records the correction and queues it, then fails.
class _FailingCorrectionRepository extends DriftBalanceCorrectionRepository {
  _FailingCorrectionRepository(super.db);

  @override
  Future<void> record(BalanceCorrection correction) async {
    await super.record(correction);
    throw Exception('disk full');
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  final at = DateTime(2026, 11, 26, 9, 30);

  CreateCustomerUseCase useCase([
    CustomerRepository? repo,
    BalanceCorrectionRepository? corrections,
  ]) {
    var next = 0;
    return CreateCustomerUseCase(
      customerRepository: repo ?? DriftCustomerRepository(db),
      transaction: driftTransactionRunner(db),
      balanceCorrections: corrections ?? DriftBalanceCorrectionRepository(db),
      now: () => at,
      newId: () => 'corr-${++next}',
    );
  }

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
    expect(await db.select(db.balanceCorrectionTable).get(), isEmpty);
    expect(await db.select(db.customerBalanceTable).get(), isEmpty);
    expect(await db.select(db.customerContainerBalanceTable).get(), isEmpty);
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

  group('opening balance', () {
    test('records the opening debt and one correction per container type '
        'with the customer, atomically and queued after it', () async {
      await useCase().execute(
        customer(),
        opening: const OpeningBalance(
          debt: 1500.5,
          containers: {'B20': 2, 'SODA': 1},
        ),
      );

      final rows = await (db.select(
        db.balanceCorrectionTable,
      )..orderBy([(t) => drift.OrderingTerm.asc(t.correctionId)])).get();
      expect(rows, hasLength(3));
      expect(
        [
          for (final r in rows)
            (
              r.correctionId,
              r.customerId,
              r.target,
              r.containerType,
              r.counted,
            ),
        ],
        [
          ('corr-1', 'cust-1', 'debt', null, 1500.5),
          ('corr-2', 'cust-1', 'containers', 'B20', 2.0),
          ('corr-3', 'cust-1', 'containers', 'SODA', 1.0),
        ],
      );
      for (final r in rows) {
        expect(r.seenBalance, 0);
        expect(r.reason, 'Saldo inicial al dar de alta');
        expect(r.reason, CreateCustomerUseCase.openingBalanceReason);
        expect(r.correctedAt, at);
        expect(r.visitId, isNull);
      }

      final shown = DriftBalanceCorrectionRepository(db);
      expect(await shown.shownBalance('cust-1', BalanceTarget.debt), 1500.5);
      expect(
        await shown.shownBalance(
          'cust-1',
          BalanceTarget.containers,
          containerType: 'B20',
        ),
        2,
      );
      expect(
        await shown.shownBalance(
          'cust-1',
          BalanceTarget.containers,
          containerType: 'SODA',
        ),
        1,
      );

      // The customer first, so the same push carries it before its
      // corrections.
      final queued = await (db.select(
        db.pendingChangeTable,
      )..orderBy([(t) => drift.OrderingTerm.asc(t.pendingChangeId)])).get();
      expect(
        [for (final c in queued) c.entity],
        [
          'customer',
          'customer_preference',
          'balance_correction',
          'balance_correction',
          'balance_correction',
        ],
      );
      final payload = jsonDecode(queued[2].payload!) as Map<String, dynamic>;
      expect(payload['customerId'], 'cust-1');
      expect(payload['seenBalance'], 0);
      expect(payload['counted'], 1500.5);
      expect(payload['reason'], 'Saldo inicial al dar de alta');
    });

    test('zero values record no correction', () async {
      await useCase().execute(
        customer(),
        opening: const OpeningBalance(debt: 0, containers: {'B20': 0}),
      );

      expect(await db.select(db.customerTable).get(), hasLength(1));
      expect(await db.select(db.balanceCorrectionTable).get(), isEmpty);
      expect(await db.select(db.customerBalanceTable).get(), isEmpty);
      expect(await db.select(db.customerContainerBalanceTable).get(), isEmpty);
      expect(await db.select(db.pendingChangeTable).get(), hasLength(2));
    });

    test('only the values above zero are recorded', () async {
      await useCase().execute(
        customer(),
        opening: const OpeningBalance(containers: {'B20': 0, 'SODA': 3}),
      );

      final row = await db.select(db.balanceCorrectionTable).getSingle();
      expect(row.target, 'containers');
      expect(row.containerType, 'SODA');
      expect(row.counted, 3);
    });

    test('a failing correction rolls the whole creation back', () async {
      await expectLater(
        useCase(
          null,
          _FailingCorrectionRepository(db),
        ).execute(customer(), opening: const OpeningBalance(debt: 800)),
        throwsA(isA<StorageFailure>()),
      );
      await expectNothingStored();
    });

    for (final (name, opening, message) in <(String, OpeningBalance, String)>[
      (
        'a negative debt',
        const OpeningBalance(debt: -100),
        CreateCustomerUseCase.negativeOpeningDebt,
      ),
      (
        'negative containers',
        const OpeningBalance(containers: {'B20': -1}),
        CorrectBalanceUseCase.invalidContainers,
      ),
      (
        'a fraction of a container',
        const OpeningBalance(containers: {'B20': 1.5}),
        CorrectBalanceUseCase.invalidContainers,
      ),
    ]) {
      test('$name throws a ValidationFailure and stores nothing', () async {
        await expectLater(
          useCase().execute(customer(), opening: opening),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.message,
              'message',
              message,
            ),
          ),
        );
        await expectNothingStored();
      });
    }
  });
}
