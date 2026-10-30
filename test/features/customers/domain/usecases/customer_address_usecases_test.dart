import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_address.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer_address.repository.dart';
import 'package:app/features/customers/domain/models/address_details.dart';
import 'package:app/features/customers/domain/usecases/add_address.usecase.dart';
import 'package:app/features/customers/domain/usecases/disable_address.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit_address.usecase.dart';
import 'package:app/features/customers/domain/usecases/set_primary_address.usecase.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// Does the whole write, then fails before the unit of work commits.
class _FailingAfterWriteRepository extends DriftCustomerAddressRepository {
  _FailingAfterWriteRepository(super.db, {super.now});

  @override
  Future<String> add(String customerId, AddressDetails details) async {
    await super.add(customerId, details);
    throw Exception('disk full');
  }

  @override
  Future<void> edit(String addressId, AddressDetails details) async {
    await super.edit(addressId, details);
    throw Exception('disk full');
  }

  @override
  Future<void> disable(String addressId) async {
    await super.disable(addressId);
    throw Exception('disk full');
  }

  @override
  Future<void> setPrimary(String addressId) async {
    await super.setPrimary(addressId);
    throw Exception('disk full');
  }
}

void main() {
  late AppDatabase db;
  final longAgo = DateTime(2020, 1, 1);
  final now = DateTime(2026, 10, 29, 12);

  Future<void> address(
    String id, {
    String customerId = 'cust-1',
    bool primary = false,
    bool enabled = true,
    int? serverId,
  }) => db
      .into(db.customerAddressTable)
      .insert(
        CustomerAddressTableCompanion.insert(
          addressId: Value(id),
          customerId: Value(customerId),
          street: Value('Street $id'),
          neighborhood: const Value('Centro'),
          isPrimary: Value(primary),
          enabled: Value(enabled),
          latitude: const Value(-24.78),
          longitude: const Value(-65.41),
          serverId: Value(serverId),
          createdAt: Value(longAgo),
          lastModifiedDate: Value(longAgo),
        ),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    for (final (id, name) in [
      ('cust-1', 'Kiosco Norte'),
      ('cust-2', 'Almacén Sur'),
      ('cust-3', 'Sin Dirección'),
    ]) {
      await db
          .into(db.customerTable)
          .insert(
            CustomerTableCompanion.insert(
              customerId: Value(id),
              name: name,
              lastModifiedDate: Value(longAgo),
            ),
          );
    }
    await address('a-1', primary: true, serverId: 101);
    await address('a-2', serverId: 102);
    await address('a-off', enabled: false, serverId: 103);
    await address('b-1', customerId: 'cust-2', primary: true, serverId: 201);
  });
  tearDown(() => db.close());

  CustomerAddressRepository repo() =>
      DriftCustomerAddressRepository(db, now: () => now);
  CustomerAddressRepository failing() =>
      _FailingAfterWriteRepository(db, now: () => now);

  AddAddressUseCase add([CustomerAddressRepository? r]) => AddAddressUseCase(
    addressRepo: r ?? repo(),
    transaction: driftTransactionRunner(db),
  );
  EditAddressUseCase edit([CustomerAddressRepository? r]) => EditAddressUseCase(
    addressRepo: r ?? repo(),
    transaction: driftTransactionRunner(db),
  );
  DisableAddressUseCase disable([CustomerAddressRepository? r]) =>
      DisableAddressUseCase(
        addressRepo: r ?? repo(),
        transaction: driftTransactionRunner(db),
      );
  SetPrimaryAddressUseCase setPrimary([CustomerAddressRepository? r]) =>
      SetPrimaryAddressUseCase(
        addressRepo: r ?? repo(),
        transaction: driftTransactionRunner(db),
      );

  Future<CustomerAddressTableData> row(String id) => (db.select(
    db.customerAddressTable,
  )..where((t) => t.addressId.equals(id))).getSingle();

  Future<List<PendingChangeTableData>> queued() => (db.select(
    db.pendingChangeTable,
  )..orderBy([(t) => OrderingTerm.asc(t.pendingChangeId)])).get();

  /// Every address row, to prove a refused or failed write changed nothing.
  Future<List<CustomerAddressTableData>> snapshot() => (db.select(
    db.customerAddressTable,
  )..orderBy([(t) => OrderingTerm.asc(t.addressId)])).get();

  Future<void> expectNothingChanged(
    List<CustomerAddressTableData> before,
  ) async {
    expect(await snapshot(), before);
    expect(await queued(), isEmpty);
  }

  Future<List<String>> enabledPrimaries(String customerId) async => [
    for (final a
        in await (db.select(db.customerAddressTable)..where(
              (t) =>
                  t.customerId.equals(customerId) &
                  t.isPrimary.equals(true) &
                  t.enabled.equals(true),
            ))
            .get())
      a.addressId,
  ];

  const valid = AddressDetails(
    street: '  Mitre 50 ',
    neighborhood: 'Centro',
    apartment: 'B',
    floor: 'PB',
    visualReference: ' Portón negro ',
  );

  /// Every way the server's limits refuse the typed fields.
  final invalid = <String, (AddressDetails, String)>{
    'no street': (
      const AddressDetails(street: '   ', neighborhood: 'Centro'),
      'La calle es requerida',
    ),
    'a street over 200': (
      AddressDetails(street: 'x' * 201),
      'La calle admite hasta 200 caracteres.',
    ),
    'an apartment over 20': (
      AddressDetails(street: 'Mitre 50', apartment: 'x' * 21),
      'El depto admite hasta 20 caracteres.',
    ),
    'a floor over 20': (
      AddressDetails(street: 'Mitre 50', floor: 'x' * 21),
      'El piso admite hasta 20 caracteres.',
    ),
    'a neighborhood over 255': (
      AddressDetails(street: 'Mitre 50', neighborhood: 'x' * 256),
      'El barrio admite hasta 255 caracteres.',
    ),
  };

  group('AddAddressUseCase', () {
    test('adds a trimmed, enabled, non-primary address dated now and queues '
        'one customer_address insert', () async {
      final id = await add().execute(customerId: 'cust-1', details: valid);

      final added = await row(id);
      expect(added.customerId, 'cust-1');
      expect(added.street, 'Mitre 50');
      expect(added.neighborhood, 'Centro');
      expect(added.apartment, 'B');
      expect(added.floor, 'PB');
      expect(added.visualReference, 'Portón negro');
      expect(added.isPrimary, isFalse);
      expect(added.enabled, isTrue);
      expect(added.serverId, isNull);
      expect(added.lastModifiedDate, now);
      expect(await enabledPrimaries('cust-1'), ['a-1']);

      final change = (await queued()).single;
      expect(change.entity, PendingEntity.customerAddress.wireName);
      expect(change.entityId, id);
      expect(change.action, PendingAction.insert.wireName);
    });

    test(
      'the first address of a customer without one is the primary',
      () async {
        final id = await add().execute(customerId: 'cust-3', details: valid);

        expect((await row(id)).isPrimary, isTrue);
        expect(await enabledPrimaries('cust-3'), [id]);
      },
    );

    test('takes the limits exactly', () async {
      final id = await add().execute(
        customerId: 'cust-1',
        details: AddressDetails(
          street: 'x' * 200,
          apartment: 'y' * 20,
          floor: 'z' * 20,
          neighborhood: 'n' * 255,
        ),
      );

      expect((await row(id)).street, 'x' * 200);
    });

    for (final MapEntry(key: name, value: (details, message))
        in invalid.entries) {
      test('refuses $name and stores nothing', () async {
        final before = await snapshot();

        await expectLater(
          add().execute(customerId: 'cust-1', details: details),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.message,
              'message',
              message,
            ),
          ),
        );
        await expectNothingChanged(before);
      });
    }

    test('a missing customer throws a NotFoundFailure', () async {
      final before = await snapshot();

      await expectLater(
        add().execute(customerId: 'ghost', details: valid),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectNothingChanged(before);
    });

    test('a failure mid-way stores nothing', () async {
      final before = await snapshot();

      await expectLater(
        add(failing()).execute(customerId: 'cust-1', details: valid),
        throwsA(isA<StorageFailure>()),
      );
      await expectNothingChanged(before);
    });
  });

  group('EditAddressUseCase', () {
    test('replaces the typed fields, keeps the flags, server id and '
        'coordinates, and queues one update', () async {
      await edit().execute(addressId: 'a-2', details: valid);

      final edited = await row('a-2');
      expect(edited.street, 'Mitre 50');
      expect(edited.visualReference, 'Portón negro');
      expect(edited.isPrimary, isFalse);
      expect(edited.enabled, isTrue);
      expect(edited.serverId, 102);
      expect(edited.latitude, -24.78);
      expect(edited.lastModifiedDate, now);

      final change = (await queued()).single;
      expect(change.entity, PendingEntity.customerAddress.wireName);
      expect(change.entityId, 'a-2');
      expect(change.action, PendingAction.update.wireName);
    });

    for (final MapEntry(key: name, value: (details, message))
        in invalid.entries) {
      test('refuses $name and changes nothing', () async {
        final before = await snapshot();

        await expectLater(
          edit().execute(addressId: 'a-2', details: details),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.message,
              'message',
              message,
            ),
          ),
        );
        await expectNothingChanged(before);
      });
    }

    for (final id in ['ghost', 'a-off']) {
      test(
        'a missing or disabled address ($id) throws a NotFoundFailure',
        () async {
          final before = await snapshot();

          await expectLater(
            edit().execute(addressId: id, details: valid),
            throwsA(isA<NotFoundFailure>()),
          );
          await expectNothingChanged(before);
        },
      );
    }

    test('a failure mid-way changes nothing', () async {
      final before = await snapshot();

      await expectLater(
        edit(failing()).execute(addressId: 'a-2', details: valid),
        throwsA(isA<StorageFailure>()),
      );
      await expectNothingChanged(before);
    });
  });

  group('DisableAddressUseCase', () {
    test('disables a secondary address, dates it now and queues one update '
        'with enabled false', () async {
      await disable().execute('a-2');

      final disabled = await row('a-2');
      expect(disabled.enabled, isFalse);
      expect(disabled.isPrimary, isFalse);
      expect(disabled.lastModifiedDate, now);
      expect(
        [for (final a in await repo().watchForCustomer('cust-1').first) a.id],
        ['a-1'],
      );

      final change = (await queued()).single;
      expect(change.entityId, 'a-2');
      expect(change.action, PendingAction.update.wireName);
      expect(jsonDecode(change.payload!), containsPair('enabled', false));
    });

    test('the primary address cannot be disabled', () async {
      final before = await snapshot();

      await expectLater(
        disable().execute('a-1'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            'La dirección principal no se puede dar de baja.',
          ),
        ),
      );
      await expectNothingChanged(before);
    });

    for (final id in ['ghost', 'a-off']) {
      test(
        'a missing or disabled address ($id) throws a NotFoundFailure',
        () async {
          final before = await snapshot();

          await expectLater(
            disable().execute(id),
            throwsA(isA<NotFoundFailure>()),
          );
          await expectNothingChanged(before);
        },
      );
    }

    test('a failure mid-way changes nothing', () async {
      final before = await snapshot();

      await expectLater(
        disable(failing()).execute('a-2'),
        throwsA(isA<StorageFailure>()),
      );
      await expectNothingChanged(before);
    });
  });

  group('SetPrimaryAddressUseCase', () {
    test('leaves exactly one enabled primary and queues the new primary '
        'before the previous one', () async {
      await setPrimary().execute('a-2');

      expect(await enabledPrimaries('cust-1'), ['a-2']);
      expect((await row('a-1')).isPrimary, isFalse);
      expect(await enabledPrimaries('cust-2'), ['b-1']);
      expect((await row('a-2')).lastModifiedDate, now);
      // The server stamps the previous primary with the new primary's date
      // when it unsets it; one second later keeps this record newer.
      expect(
        (await row('a-1')).lastModifiedDate,
        now.add(const Duration(seconds: 1)),
      );

      final changes = await queued();
      expect([for (final c in changes) c.entityId], ['a-2', 'a-1']);
      expect(changes.map((c) => c.entity).toSet(), {
        PendingEntity.customerAddress.wireName,
      });
      expect(changes.map((c) => c.action).toSet(), {
        PendingAction.update.wireName,
      });
    });

    test('the primary first in the list', () async {
      await setPrimary().execute('a-2');

      expect(
        [for (final a in await repo().watchForCustomer('cust-1').first) a.id],
        ['a-2', 'a-1'],
      );
    });

    test('the current primary changes nothing', () async {
      final before = await snapshot();

      await setPrimary().execute('a-1');

      await expectNothingChanged(before);
    });

    for (final id in ['ghost', 'a-off']) {
      test(
        'a missing or disabled address ($id) throws a NotFoundFailure',
        () async {
          final before = await snapshot();

          await expectLater(
            setPrimary().execute(id),
            throwsA(isA<NotFoundFailure>()),
          );
          await expectNothingChanged(before);
        },
      );
    }

    test('a failure mid-way keeps the previous primary', () async {
      final before = await snapshot();

      await expectLater(
        setPrimary(failing()).execute('a-2'),
        throwsA(isA<StorageFailure>()),
      );
      await expectNothingChanged(before);
      expect(await enabledPrimaries('cust-1'), ['a-1']);
    });
  });
}
