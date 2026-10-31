import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/domain/models/customer_edit.dart';
import 'package:app/features/customers/domain/usecases/edit.customer.usecase.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// Writes the edit and queues it, then fails.
class _FailingAfterWriteRepository extends DriftCustomerRepository {
  _FailingAfterWriteRepository(super.db);

  @override
  Future<void> editCustomer(CustomerEdit edit) async {
    await super.editCustomer(edit);
    throw Exception('disk full');
  }
}

void main() {
  late AppDatabase db;
  final longAgo = DateTime(2020, 1, 1);

  // A customer already synced: it and its address carry server ids.
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.customerTable).insert(
      CustomerTableCompanion.insert(
        customerId: const Value('cust-1'),
        name: 'Kiosco Norte',
        phone: const Value('3874001122'),
        serverId: const Value(501),
        lastModifiedDate: Value(longAgo),
      ),
    );
    await db.into(db.customerAddressTable).insert(
      CustomerAddressTableCompanion.insert(
        addressId: const Value('addr-1'),
        customerId: const Value('cust-1'),
        street: const Value('Belgrano 1200'),
        neighborhood: const Value('Centro'),
        isPrimary: const Value(true),
        latitude: const Value(-24.78),
        longitude: const Value(-65.41),
        serverId: const Value(601),
        lastModifiedDate: Value(longAgo),
      ),
    );
    await db.into(db.customerPreferenceTable).insert(
      CustomerPreferenceTableCompanion.insert(
        customerPreferenceId: const Value('pref-1'),
        customerId: const Value('cust-1'),
        timeWindowStart: '09:00',
      ),
    );
  });
  tearDown(() => db.close());

  EditCustomerUseCase useCase([CustomerRepository? repo]) =>
      EditCustomerUseCase(
        customerRepository: repo ?? DriftCustomerRepository(db),
        transaction: driftTransactionRunner(db),
      );

  CustomerEdit edit({String customerId = 'cust-1', String name = 'Kiosco Sur'}) =>
      CustomerEdit(
        customerId: customerId,
        name: name,
        phone: '3874009988',
        street: 'Mitre 50',
        neighborhood: 'Tres Cerritos',
        apartment: 'B',
        floor: 'PB',
        visualReference: 'Portón verde',
      );

  Future<void> expectUnchanged() async {
    final customer = await db.select(db.customerTable).getSingle();
    expect(customer.name, 'Kiosco Norte');
    expect(customer.phone, '3874001122');
    final address = await db.select(db.customerAddressTable).getSingle();
    expect(address.street, 'Belgrano 1200');
    expect(address.lastModifiedDate, longAgo);
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
  }

  test(
    'edits name, phone and the address in place and queues one customer update',
    () async {
      await useCase().execute(edit());

      final customer = await db.select(db.customerTable).getSingle();
      expect(customer.name, 'Kiosco Sur');
      expect(customer.phone, '3874009988');
      expect(customer.serverId, 501);
      expect(customer.lastModifiedDate.isAfter(longAgo), isTrue);

      final address = await db.select(db.customerAddressTable).getSingle();
      expect(address.addressId, 'addr-1');
      expect(address.serverId, 601);
      expect(address.isPrimary, isTrue);
      expect(address.street, 'Mitre 50');
      expect(address.neighborhood, 'Tres Cerritos');
      expect(address.apartment, 'B');
      expect(address.floor, 'PB');
      expect(address.visualReference, 'Portón verde');
      // Coordinates are not part of the edit; the stored ones stay.
      expect(address.latitude, -24.78);
      expect(address.longitude, -65.41);
      expect(address.lastModifiedDate.isAfter(longAgo), isTrue);

      // Preferences do not sync and are not part of the edit.
      expect(await db.select(db.customerPreferenceTable).get(), hasLength(1));

      final change = await db.select(db.pendingChangeTable).getSingle();
      expect(change.entity, PendingEntity.customer.wireName);
      expect(change.entityId, 'cust-1');
      expect(change.action, PendingAction.update.wireName);
      // The push sends only these, so untouched fields stay as the server
      // holds them.
      expect(
        jsonDecode(change.payload!)[PendingChange.changedFieldsKey],
        unorderedEquals([
          'name',
          'phone_number',
          'address.street',
          'address.neighborhood',
          'address.apartment',
          'address.floor',
          'address.visual_reference',
        ]),
      );
    },
  );

  test('a customer without an address gets one that travels', () async {
    await db.delete(db.customerAddressTable).go();

    await useCase().execute(edit());

    final address = await db.select(db.customerAddressTable).getSingle();
    expect(address.customerId, 'cust-1');
    expect(address.street, 'Mitre 50');
    expect(address.isPrimary, isTrue);
  });

  test('an empty name throws a ValidationFailure and changes nothing', () async {
    await expectLater(
      useCase().execute(edit(name: '  ')),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'El nombre es requerido',
        ),
      ),
    );
    await expectUnchanged();
  });

  test('a missing customer throws a NotFoundFailure and queues nothing', () async {
    await expectLater(
      useCase().execute(edit(customerId: 'ghost')),
      throwsA(isA<NotFoundFailure>()),
    );
    await expectUnchanged();
  });

  test('a failure mid-way leaves the customer, address and queue unchanged', () async {
    await expectLater(
      useCase(_FailingAfterWriteRepository(db)).execute(edit()),
      throwsA(isA<StorageFailure>()),
    );
    await expectUnchanged();
  });
}
