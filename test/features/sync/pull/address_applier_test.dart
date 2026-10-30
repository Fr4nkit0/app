import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/pull/address_applier.dart';
import 'package:app/features/sync/pull/pull_applier.dart' show Json;

import 'pull_support.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = memoryDatabase();
    await seedCustomer(db, id: 'cust-1', serverId: 11);
  });
  tearDown(() => db.close());

  Future<void> local(
    String id, {
    bool primary = false,
    int? serverId,
    String? street,
  }) => db
      .into(db.customerAddressTable)
      .insert(
        CustomerAddressTableCompanion.insert(
          addressId: Value(id),
          customerId: const Value('cust-1'),
          street: Value(street ?? 'Street $id'),
          isPrimary: Value(primary),
          serverId: Value(serverId),
        ),
      );

  Json server(
    int id, {
    String? clientUuid,
    String street = 'Server street',
    bool primary = false,
    bool enabled = true,
  }) => {
    'id': id,
    'client_uuid': clientUuid,
    'customer_id': 11,
    'street': street,
    'is_primary': primary,
    'enabled': enabled,
  };

  Future<void> pull(List<Json> rows) async => AddressApplier(
    db,
  ).applyChanges({'customer_addresses': rows}, await pullContext(db));

  Future<List<CustomerAddressTableData>> rows() => (db.select(
    db.customerAddressTable,
  )..orderBy([(t) => OrderingTerm.asc(t.addressId)])).get();

  test('links a second address by its client uuid, not the unlinked '
      'primary', () async {
    await local('a-1', primary: true);
    await local('a-2');

    await pull([server(202, clientUuid: 'a-2', street: 'Street a-2')]);

    final stored = await rows();
    expect(stored, hasLength(2));
    expect(stored.firstWhere((a) => a.addressId == 'a-2').serverId, 202);
    expect(stored.firstWhere((a) => a.addressId == 'a-1').serverId, isNull);
  });

  test('a server address with an unknown client uuid is stored under that '
      'uuid and never duplicated by a later pull', () async {
    await local('a-1', primary: true, serverId: 101);

    await pull([server(202, clientUuid: 'a-other', street: 'Mitre 50')]);
    await pull([server(202, clientUuid: 'a-other', street: 'Mitre 51')]);

    final stored = await rows();
    expect([for (final a in stored) a.addressId], ['a-1', 'a-other']);
    final other = stored.last;
    expect(other.serverId, 202);
    expect(other.street, 'Mitre 51');
  });

  test(
    'every address of a customer arrives once, disabled ones included',
    () async {
      await pull([
        server(101, clientUuid: 'a-1', primary: true),
        server(102, clientUuid: 'a-2'),
        server(103, clientUuid: 'a-3', enabled: false),
      ]);
      await pull([
        server(101, clientUuid: 'a-1', primary: true),
        server(102, clientUuid: 'a-2'),
        server(103, clientUuid: 'a-3', enabled: false),
      ]);

      final stored = await rows();
      expect([for (final a in stored) a.addressId], ['a-1', 'a-2', 'a-3']);
      expect([for (final a in stored) a.enabled], [true, true, false]);
      expect([for (final a in stored) a.isPrimary], [true, false, false]);
    },
  );

  test('an address with an unsent change keeps its local values and gets '
      'linked', () async {
    await local('a-2', street: 'Mitre 50');
    await enqueueUnsent(db, PendingEntity.customerAddress, 'a-2');

    await pull([server(202, clientUuid: 'a-2', street: 'Old street')]);

    final stored = (await rows()).single;
    expect(stored.street, 'Mitre 50');
    expect(stored.serverId, 202);
  });

  test(
    'an unsent primary switch is not undone by an older server copy',
    () async {
      await local('a-1', serverId: 101);
      await local('a-2', primary: true, serverId: 102);
      await enqueueUnsent(db, PendingEntity.customerAddress, 'a-2');
      await enqueueUnsent(db, PendingEntity.customerAddress, 'a-1');

      await pull([
        server(101, clientUuid: 'a-1', primary: true),
        server(102, clientUuid: 'a-2'),
      ]);

      final stored = await rows();
      expect([for (final a in stored) a.isPrimary], [false, true]);
    },
  );

  test('a new server primary does not add a second primary while the '
      'customer has unsent address changes', () async {
    await local('a-1', primary: true, serverId: 101);
    await enqueueUnsent(db, PendingEntity.customerAddress, 'a-1');

    await pull([server(303, clientUuid: 'a-web', primary: true)]);

    final stored = await rows();
    expect([for (final a in stored) a.addressId], ['a-1', 'a-web']);
    expect([for (final a in stored) a.isPrimary], [true, false]);
  });

  test('a legacy server row without client uuid is not linked to an address '
      'that travels on its own', () async {
    await local('a-new', primary: true);
    await enqueueUnsent(db, PendingEntity.customerAddress, 'a-new');

    await pull([server(404, primary: true)]);

    final stored = await rows();
    expect(stored, hasLength(2));
    expect(stored.firstWhere((a) => a.addressId == 'a-new').serverId, isNull);
  });
}
