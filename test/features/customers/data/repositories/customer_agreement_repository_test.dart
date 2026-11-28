import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/drift.customer_agreement.repository.dart';
import 'package:app/features/customers/domain/models/agreement_terms.dart';
import 'package:app/features/customers/domain/models/customer_agreement.dart';
import 'package:app/features/products/data/repositories/drift.product.repository.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

void main() {
  late AppDatabase db;
  late DriftCustomerAgreementRepository sut;
  final today = DateTime(2026, 10, 22);
  final now = DateTime(2026, 10, 22, 9, 30);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftCustomerAgreementRepository(db, now: () => now);
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
          ),
        );
    await db
        .into(db.productTable)
        .insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('p-1'),
            name: 'Agua 20L',
            price: 1500,
          ),
        );
  });
  tearDown(() => db.close());

  Future<String> create({
    int price = 1200,
    String validFrom = '2026-10-22',
    String? validTo,
    String? reason,
  }) => sut.create(
    customerId: 'c-1',
    productId: 'p-1',
    unitPrice: price,
    validFrom: validFrom,
    validTo: validTo,
    reason: reason,
  );

  test('create stores the agreement and queues it in the same step', () async {
    final id = await create(reason: 'Cliente mayorista');

    final row = await db.select(db.customerAgreementTable).getSingle();
    expect(row.agreementId, id);
    expect(row.serverId, isNull);
    expect(row.unitPrice, 1200);
    expect(row.reason, 'Cliente mayorista');

    final pending = await DriftPendingChangeRepository(db).getPending();
    expect(pending, hasLength(1));
    expect(pending.single.entity, PendingEntity.customerAgreement);
    expect(pending.single.entityId, id);
    expect(pending.single.action, PendingAction.insert);
  });

  test('create changes the price the customer pays right away', () async {
    final id = await create();

    final products = await DriftProductRepository(
      db,
    ).watchProductsFor('c-1').first;
    expect(products.single.price, 1200);
    expect(products.single.agreementId, isNull);
    expect(products.single.agreementUuid, id);
  });

  test('watch lists the agreements in force first with their status', () async {
    await create(price: 1000, validFrom: '2026-01-01', validTo: '2026-02-01');
    await create(price: 1100, validFrom: '2027-01-01');
    await create(price: 1200, validFrom: '2026-10-01');

    final list = await sut.watchForCustomer('c-1', today: today).first;

    expect(list.map((a) => a.unitPrice), [1200, 1100, 1000]);
    expect(list.map((a) => a.status), [
      AgreementStatus.inForce,
      AgreementStatus.future,
      AgreementStatus.ended,
    ]);
    expect(list.first.productName, 'Agua 20L');
    expect(list.first.isSynced, isFalse);
  });

  test(
    'create stamps the agreement with the local modification time',
    () async {
      final id = await create();

      expect((await rowOf(db, id)).lastModifiedDate, now);
    },
  );

  group('changing an agreement', () {
    final longAgo = DateTime(2026, 1, 1);

    Future<void> insertSynced(
      String id, {
      int price = 1000,
      String from = '2026-10-01',
      String? to,
      int serverId = 7,
    }) => db
        .into(db.customerAgreementTable)
        .insert(
          CustomerAgreementTableCompanion.insert(
            agreementId: drift.Value(id),
            customerId: 'c-1',
            productId: 'p-1',
            unitPrice: price,
            validFrom: from,
            validTo: drift.Value(to),
            serverId: drift.Value(serverId),
            lastModifiedDate: drift.Value(longAgo),
          ),
        );

    Future<List<PendingChange>> pending() =>
        DriftPendingChangeRepository(db).getPending();

    const terms = AgreementTerms(
      unitPrice: 1300,
      validFrom: '2026-11-01',
      validTo: '2026-12-31',
      reason: 'Nuevo precio',
    );

    test(
      'findEnabled returns the agreement and skips a disabled one',
      () async {
        await insertSynced('a-1');

        final found = await sut.findEnabled('a-1');
        expect(found?.unitPrice, 1000);
        expect(found?.validFrom, '2026-10-01');
        expect(found?.isSynced, isTrue);

        await sut.disable('a-1');
        expect(await sut.findEnabled('a-1'), isNull);
        expect(await sut.findEnabled('missing'), isNull);
      },
    );

    test('edit writes the terms in place and queues an update', () async {
      await insertSynced('a-1', from: '2026-11-01');

      await sut.edit('a-1', terms);

      final row = await rowOf(db, 'a-1');
      expect(row.unitPrice, 1300);
      expect(row.validFrom, '2026-11-01');
      expect(row.validTo, '2026-12-31');
      expect(row.reason, 'Nuevo precio');
      expect(row.customerId, 'c-1');
      expect(row.productId, 'p-1');
      expect(row.serverId, 7);
      expect(row.enabled, isTrue);
      expect(row.lastModifiedDate, now);
      final change = (await pending()).single;
      expect(change.entity, PendingEntity.customerAgreement);
      expect(change.entityId, 'a-1');
      expect(change.action, PendingAction.update);
    });

    test('edit can clear the end and the reason', () async {
      final id = await create(validTo: '2026-12-01', reason: 'Mayorista');

      await sut.edit(
        id,
        const AgreementTerms(unitPrice: 1200, validFrom: '2026-10-22'),
      );

      final row = await rowOf(db, id);
      expect(row.validTo, isNull);
      expect(row.reason, isNull);
    });

    test('disable hides the agreement and queues an update', () async {
      await insertSynced('a-1');

      await sut.disable('a-1');

      final row = await rowOf(db, 'a-1');
      expect(row.enabled, isFalse);
      expect(row.lastModifiedDate, now);
      final change = (await pending()).single;
      expect(change.entityId, 'a-1');
      expect(change.action, PendingAction.update);
      expect(await sut.watchForCustomer('c-1', today: today).first, isEmpty);
    });

    test('deleteUnsynced removes the row and its pending changes', () async {
      final id = await create();
      await sut.edit(id, terms);

      await sut.deleteUnsynced(id);

      expect(await db.select(db.customerAgreementTable).get(), isEmpty);
      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    });

    test('deleteUnsynced leaves a synced agreement alone', () async {
      await insertSynced('a-1');

      await sut.deleteUnsynced('a-1');

      expect((await rowOf(db, 'a-1')).enabled, isTrue);
    });

    test('replace closes the old one yesterday and creates the new one '
        'after it in the queue', () async {
      await insertSynced('a-old', from: '2026-10-01');

      final newId = await sut.replace('a-old', terms, today: today);

      expect(newId, isNot('a-old'));
      final old = await rowOf(db, 'a-old');
      expect(old.validTo, '2026-10-21');
      expect(old.unitPrice, 1000);
      expect(old.validFrom, '2026-10-01');
      expect(old.enabled, isTrue);
      expect(old.lastModifiedDate, now);

      final fresh = await rowOf(db, newId);
      expect(fresh.customerId, 'c-1');
      expect(fresh.productId, 'p-1');
      expect(fresh.unitPrice, 1300);
      expect(fresh.validFrom, '2026-11-01');
      expect(fresh.validTo, '2026-12-31');
      expect(fresh.reason, 'Nuevo precio');
      expect(fresh.serverId, isNull);
      expect(fresh.enabled, isTrue);

      final changes = await pending();
      expect(changes, hasLength(2));
      expect(changes[0].entityId, 'a-old');
      expect(changes[0].action, PendingAction.update);
      expect(changes[1].entityId, newId);
      expect(changes[1].action, PendingAction.insert);
      expect(changes[0].id, lessThan(changes[1].id));
    });

    test('replace disables the old one when it started today', () async {
      await insertSynced('a-old', from: '2026-10-22');

      final newId = await sut.replace('a-old', terms, today: today);

      final old = await rowOf(db, 'a-old');
      expect(old.enabled, isFalse);
      expect(old.validTo, isNull);
      final changes = await pending();
      expect(changes.map((c) => (c.entityId, c.action)), [
        ('a-old', PendingAction.update),
        (newId, PendingAction.insert),
      ]);
    });

    test('replace never moves an earlier end later', () async {
      await insertSynced('a-old', from: '2026-09-01', to: '2026-10-10');

      await sut.replace('a-old', terms, today: today);

      expect((await rowOf(db, 'a-old')).validTo, '2026-10-10');
    });
  });
}

Future<CustomerAgreementTableData> rowOf(AppDatabase db, String id) =>
    (db.select(
      db.customerAgreementTable,
    )..where((t) => t.agreementId.equals(id))).getSingle();
