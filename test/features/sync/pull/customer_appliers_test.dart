import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/pull/address_applier.dart';
import 'package:app/features/sync/pull/customer_applier.dart';
import 'package:app/features/sync/pull/preference_applier.dart';

import 'pull_support.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<CustomerTableData> customer(String id) => (db.select(
    db.customerTable,
  )..where((t) => t.customerId.equals(id))).getSingle();

  group('CustomerApplier', () {
    test('links a customer created on the device by its client uuid', () async {
      await seedCustomer(db, id: 'cust-uuid', name: 'Ana');
      final context = await pullContext(db);

      await CustomerApplier(db).applyChanges({
        'customers': [
          {
            'id': 11,
            'client_uuid': 'cust-uuid',
            'name': 'Ana María',
            'phone_number': '9',
          },
        ],
      }, context);

      final rows = await db.select(db.customerTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.serverId, 11);
      expect(rows.single.name, 'Ana María');
    });

    test(
      'keeps a customer with unsent changes and still maps its id',
      () async {
        await seedCustomer(
          db,
          id: 'cust-1',
          serverId: 11,
          name: 'Ana (edited)',
        );
        await enqueueUnsent(db, PendingEntity.customer, 'cust-1');
        final context = await bootstrapContext(db);

        final localId = await CustomerApplier(db).upsert({
          'id': 11,
          'client_uuid': null,
          'name': 'Ana',
          'phone_number': null,
        }, context);

        expect(localId, 'cust-1');
        expect((await customer('cust-1')).name, 'Ana (edited)');
        expect(await context.ids.customer(11), 'cust-1');
      },
    );
  });

  group('AddressApplier', () {
    test(
      'links the device primary address instead of adding another one',
      () async {
        await seedCustomer(db, id: 'cust-1', serverId: 11);
        await db
            .into(db.customerAddressTable)
            .insert(
              CustomerAddressTableCompanion.insert(
                addressId: const Value('addr-local'),
                customerId: const Value('cust-1'),
                street: const Value('Belgrano 340'),
                isPrimary: const Value(true),
              ),
            );
        final context = await pullContext(db);

        await AddressApplier(db).applyChanges({
          'customer_addresses': [
            {
              'id': 111,
              'customer_id': 11,
              'street': 'Belgrano 340',
              'is_primary': true,
            },
          ],
        }, context);

        final rows = await db.select(db.customerAddressTable).get();
        expect(rows, hasLength(1));
        expect(rows.single.addressId, 'addr-local');
        expect(rows.single.serverId, 111);
      },
    );

    for (final serverPrimary in [true, false]) {
      test(
        'links an address created on the device without the primary flag '
        '(server is_primary: $serverPrimary)',
        () async {
          await seedCustomer(db, id: 'cust-1', serverId: 11);
          await db
              .into(db.customerAddressTable)
              .insert(
                CustomerAddressTableCompanion.insert(
                  addressId: const Value('addr-local'),
                  customerId: const Value('cust-1'),
                  street: const Value('Belgrano 100'),
                  floor: const Value('PB'),
                ),
              );
          final context = await pullContext(db);

          await AddressApplier(db).applyChanges({
            'customer_addresses': [
              {
                'id': 111,
                'customer_id': 11,
                'street': 'Belgrano 100',
                'floor': 'PB',
                'is_primary': serverPrimary,
              },
            ],
          }, context);

          final rows = await db.select(db.customerAddressTable).get();
          expect(rows, hasLength(1));
          expect(rows.single.addressId, 'addr-local');
          expect(rows.single.serverId, 111);
          expect(rows.single.floor, 'PB');
        },
      );
    }

    test(
      'only links the server id of a customer with unsent changes',
      () async {
        await seedCustomer(db, id: 'cust-1', serverId: 11);
        await db
            .into(db.customerAddressTable)
            .insert(
              CustomerAddressTableCompanion.insert(
                addressId: const Value('addr-1'),
                customerId: const Value('cust-1'),
                street: const Value('Edited on the device'),
                serverId: const Value(111),
              ),
            );
        await enqueueUnsent(db, PendingEntity.customer, 'cust-1');
        final context = await bootstrapContext(db);

        await AddressApplier(db).applyForCustomer('cust-1', [
          {'id': 111, 'street': 'Server street', 'is_primary': false},
        ], context);

        final row = await db.select(db.customerAddressTable).getSingle();
        expect(row.street, 'Edited on the device');
        expect(await context.ids.address(111), 'addr-1');
      },
    );

    test('skips an address whose customer is not on the device', () async {
      final context = await pullContext(db);

      await AddressApplier(db).applyChanges({
        'customer_addresses': [
          {
            'id': 131,
            'customer_id': 13,
            'street': 'Mitre 10',
            'is_primary': true,
          },
        ],
      }, context);

      expect(await db.select(db.customerAddressTable).get(), isEmpty);
    });
  });

  group('PreferenceApplier', () {
    Map<String, dynamic> preference(String start) => {
      'id': 500,
      'customer_id': 11,
      'day_of_week': 2,
      'time_window_start': start,
      'time_window_end': null,
    };

    test('keeps the preference of a customer with unsent changes', () async {
      await seedCustomer(db, id: 'cust-1', serverId: 11);
      final applier = PreferenceApplier(db);
      await applier.applyChanges({
        'customer_preferences': [preference('08:00:00')],
      }, await pullContext(db));
      await enqueueUnsent(db, PendingEntity.customer, 'cust-1');

      await applier.applyChanges({
        'customer_preferences': [preference('10:00:00')],
      }, await pullContext(db));

      final row = await db.select(db.customerPreferenceTable).getSingle();
      expect(row.timeWindowStart, '08:00:00');
    });

    test('skips a preference whose customer is not on the device', () async {
      await PreferenceApplier(db).applyChanges({
        'customer_preferences': [preference('08:00:00')],
      }, await pullContext(db));

      expect(await db.select(db.customerPreferenceTable).get(), isEmpty);
    });
  });
}
