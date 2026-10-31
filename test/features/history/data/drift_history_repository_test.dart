import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/history/data/repositories/history.repository.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

void main() {
  late AppDatabase db;
  late DriftPendingChangeRepository queue;
  late DriftHistoryRepository sut;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    queue = DriftPendingChangeRepository(db);
    sut = DriftHistoryRepository(db);
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const Value('cus-1'),
            name: 'Ana Gómez',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertSale(String id, double total) => db
      .into(db.saleTable)
      .insert(
        SaleTableCompanion.insert(
          saleId: Value(id),
          customerId: 'cus-1',
          totalAmount: total,
          paymentMethod: 'cash',
          quantity: 2,
          shipping_amount: 0,
        ),
      );

  Future<void> insertPayment(String id, double amount) => db
      .into(db.paymentTable)
      .insert(
        PaymentTableCompanion.insert(
          paymentId: Value(id),
          customerId: 'cus-1',
          amount: amount,
          paymentMethod: 'cash',
        ),
      );

  test('lists real records newest first with customer, amount, status and '
      'rejection reason', () async {
    await insertSale('sale-1', 4500);
    await queue.enqueue(
      entity: PendingEntity.sale,
      entityId: 'sale-1',
      action: PendingAction.insert,
    );
    await insertPayment('pay-1', 1200);
    await queue.enqueue(
      entity: PendingEntity.payment,
      entityId: 'pay-1',
      action: PendingAction.insert,
    );
    final ids = (await queue.getPending()).map((c) => c.id).toList();
    await queue.markSent([ids.first]);
    await queue.markRejected(ids.last, 'Cliente dado de baja');

    final entries = await sut.watchHistory().first;

    expect(entries, hasLength(2));
    final payment = entries.first;
    expect(payment.type, HistoryEntryType.payment);
    expect(payment.customerId, 'cus-1');
    expect(payment.customerName, 'Ana Gómez');
    expect(payment.amount, 1200);
    expect(payment.status, PendingStatus.rejected);
    expect(payment.rejectionReason, 'Cliente dado de baja');

    final sale = entries.last;
    expect(sale.type, HistoryEntryType.sale);
    expect(sale.amount, 4500);
    expect(sale.status, PendingStatus.sent);
    expect(sale.rejectionReason, isNull);
  });

  test('lists a customer created on the street as a pending record', () async {
    await queue.enqueue(
      entity: PendingEntity.customer,
      entityId: 'cus-1',
      action: PendingAction.insert,
    );

    final entry = (await sut.watchHistory().first).single;

    expect(entry.type, HistoryEntryType.customer);
    expect(entry.customerName, 'Ana Gómez');
    expect(entry.description, 'Cliente nuevo');
    expect(entry.status, PendingStatus.pending);
  });

  test('lists a price agreement created on the street', () async {
    await db
        .into(db.productTable)
        .insert(
          ProductTableCompanion.insert(
            productId: const Value('p-1'),
            name: 'Agua 20L',
            price: 1500,
          ),
        );
    await db
        .into(db.customerAgreementTable)
        .insert(
          CustomerAgreementTableCompanion.insert(
            agreementId: const Value('a-1'),
            customerId: 'cus-1',
            productId: 'p-1',
            unitPrice: 1200,
            validFrom: '2026-10-22',
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.customerAgreement,
      entityId: 'a-1',
      action: PendingAction.insert,
    );

    final entry = (await sut.watchHistory().first).single;

    expect(entry.type, HistoryEntryType.agreement);
    expect(entry.customerName, 'Ana Gómez');
    expect(entry.amount, 1200);
    expect(entry.description, 'Acuerdo de precio creado');
    expect(entry.status, PendingStatus.pending);
  });

  test('lists address changes as customer records of their customer', () async {
    await db
        .into(db.customerAddressTable)
        .insert(
          CustomerAddressTableCompanion.insert(
            addressId: const Value('addr-1'),
            customerId: const Value('cus-1'),
            street: const Value('Mitre 50'),
          ),
        );
    for (final (action, payload) in [
      (PendingAction.insert, null),
      (PendingAction.update, {'addressId': 'addr-1'}),
      (PendingAction.update, {'addressId': 'addr-1', 'enabled': false}),
    ]) {
      await queue.enqueue(
        entity: PendingEntity.customerAddress,
        entityId: 'addr-1',
        action: action,
        payload: payload,
      );
    }

    final entries = await sut.watchHistory().first;

    expect(
      [for (final e in entries) e.description],
      ['Dirección desactivada', 'Dirección actualizada', 'Dirección agregada'],
    );
    for (final entry in entries) {
      expect(entry.type, HistoryEntryType.customer);
      expect(entry.customerId, 'cus-1');
      expect(entry.customerName, 'Ana Gómez');
    }
  });

  test('lists preference changes as customer records of their '
      'customer', () async {
    await db
        .into(db.customerPreferenceTable)
        .insert(
          CustomerPreferenceTableCompanion.insert(
            customerPreferenceId: const Value('pref-1'),
            customerId: const Value('cus-1'),
            timeWindowStart: '09:00',
          ),
        );
    for (final (action, payload) in [
      (PendingAction.insert, null),
      (PendingAction.update, {'preferenceId': 'pref-1'}),
      (PendingAction.update, {'preferenceId': 'pref-1', 'enabled': true}),
      (PendingAction.update, {'preferenceId': 'pref-1', 'enabled': false}),
    ]) {
      await queue.enqueue(
        entity: PendingEntity.customerPreference,
        entityId: 'pref-1',
        action: action,
        payload: payload,
      );
    }

    final entries = await sut.watchHistory().first;

    expect(
      [for (final e in entries) e.description],
      [
        'Preferencia desactivada',
        'Preferencia actualizada',
        'Preferencia actualizada',
        'Preferencia agregada',
      ],
    );
    for (final entry in entries) {
      expect(entry.type, HistoryEntryType.customer);
      expect(entry.customerId, 'cus-1');
      expect(entry.customerName, 'Ana Gómez');
    }
  });

  test('a rejected record whose local row was deleted still names its '
      'customer', () async {
    // The rollback of a rejected preference create deletes the local row;
    // the queue entry keeps the customer id in its payload.
    await queue.enqueue(
      entity: PendingEntity.customerPreference,
      entityId: 'pref-gone',
      action: PendingAction.insert,
      payload: {'preferenceId': 'pref-gone', 'customerId': 'cus-1'},
    );

    final entry = (await sut.watchHistory().first).single;

    expect(entry.customerId, 'cus-1');
    expect(entry.customerName, 'Ana Gómez');
  });

  test('emits again when the server answers a record', () async {
    await insertSale('sale-1', 4500);
    await queue.enqueue(
      entity: PendingEntity.sale,
      entityId: 'sale-1',
      action: PendingAction.insert,
    );
    final statuses = sut.watchHistory().map((l) => l.single.status);

    final expectation = expectLater(
      statuses,
      emitsInOrder([PendingStatus.pending, PendingStatus.rejected]),
    );
    await Future<void>.delayed(Duration.zero);
    final id = (await queue.getPending()).single.id;
    await queue.markRejected(id, 'Precio inválido');

    await expectation;
  });

  group('a visited stop', () {
    setUp(() async {
      await db
          .into(db.routeTable)
          .insert(
            RouteTableCompanion.insert(
              routeId: const Value('r-1'),
              route_date: '2026-10-29',
            ),
          );
      await db
          .into(db.routeStopTable)
          .insert(
            RouteStopTableCompanion.insert(
              routeStopId: const Value('stop-1'),
              routeId: 'r-1',
              customerId: 'cus-1',
              sequence: 1,
              scheduledAt: DateTime(2026, 10, 29, 9),
            ),
          );
      await db
          .into(db.visitOutcomeTable)
          .insert(
            VisitOutcomeTableCompanion.insert(
              id: const Value(2),
              code: const Value('refused'),
              name: 'No quiso',
            ),
          );
    });

    Future<void> recordVisit({int? outcomeId, String? observations}) async {
      await db
          .into(db.visitTable)
          .insert(
            VisitTableCompanion.insert(
              visitId: const Value('visit-1'),
              routeStopId: 'stop-1',
              customerId: 'cus-1',
              visitType: 'visit',
              outcomeId: Value(outcomeId),
              observations: Value(observations),
              arrived_at: DateTime(2026, 10, 29, 10),
            ),
          );
      await queue.enqueue(
        entity: PendingEntity.visit,
        entityId: 'visit-1',
        action: PendingAction.insert,
      );
    }

    test('a visit row shows its outcome', () async {
      await recordVisit(outcomeId: 2);

      final entry = (await sut.watchHistory().first).single;

      expect(entry.type, HistoryEntryType.visit);
      expect(entry.description, 'No quiso');
    });

    test('a visit row shows its outcome before the observations', () async {
      await recordVisit(outcomeId: 2, observations: 'Volver el lunes');

      final entry = (await sut.watchHistory().first).single;

      expect(entry.description, 'No quiso · Volver el lunes');
    });

    test('a visit without outcome keeps the generic label', () async {
      await recordVisit();

      final entry = (await sut.watchHistory().first).single;

      expect(entry.description, 'Visita registrada');
    });

    test('the stop update that duplicates the visit is not listed', () async {
      await queue.enqueue(
        entity: PendingEntity.routeStop,
        entityId: 'stop-1',
        action: PendingAction.update,
      );
      await recordVisit(outcomeId: 2);

      final entries = await sut.watchHistory().first;

      expect(entries.map((e) => e.type), [HistoryEntryType.visit]);
    });

    test('a reschedule of the visited stop is still listed', () async {
      await queue.enqueue(
        entity: PendingEntity.routeStop,
        entityId: 'stop-1',
        action: PendingAction.update,
      );
      await db
          .into(db.routeStopTable)
          .insert(
            RouteStopTableCompanion.insert(
              routeStopId: const Value('stop-2'),
              routeId: 'r-1',
              customerId: 'cus-1',
              sequence: 2,
              scheduledAt: DateTime(2026, 10, 29, 16),
              rescheduledFromStopId: const Value('stop-1'),
            ),
          );
      await queue.enqueue(
        entity: PendingEntity.routeStop,
        entityId: 'stop-2',
        action: PendingAction.insert,
      );
      await recordVisit();

      final entries = await sut.watchHistory().first;

      expect(entries.map((e) => e.description), [
        'Visita registrada',
        'Parada reprogramada',
      ]);
    });
  });

  test('a stop update without a visit is still listed', () async {
    await queue.enqueue(
      entity: PendingEntity.routeStop,
      entityId: 'stop-9',
      action: PendingAction.update,
    );

    final entry = (await sut.watchHistory().first).single;

    expect(entry.description, 'Parada actualizada');
  });

  test('a credit sale is marked as credit', () async {
    await db
        .into(db.saleTable)
        .insert(
          SaleTableCompanion.insert(
            saleId: const Value('sale-1'),
            customerId: 'cus-1',
            totalAmount: 1900,
            paymentMethod: 'credit',
            quantity: 1,
            shipping_amount: 0,
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.sale,
      entityId: 'sale-1',
      action: PendingAction.insert,
    );

    final entry = (await sut.watchHistory().first).single;

    expect(entry.description, 'Venta a crédito');
    expect(entry.amount, 1900);
  });

  test('a cash sale keeps the generic label', () async {
    await insertSale('sale-1', 4500);
    await queue.enqueue(
      entity: PendingEntity.sale,
      entityId: 'sale-1',
      action: PendingAction.insert,
    );

    final entry = (await sut.watchHistory().first).single;

    expect(entry.description, 'Venta registrada');
  });

  test(
    'a rejected or outdated edit carries what was refused or dropped',
    () async {
      for (final fields in [
        ['phone_number'],
        ['name'],
      ]) {
        await queue.enqueue(
          entity: PendingEntity.customer,
          entityId: 'cus-1',
          action: PendingAction.update,
          payload: {PendingChange.changedFieldsKey: fields},
        );
      }
      final [rejected, outdated] = await queue.getPending();
      await queue.markRejected(rejected.id, 'invalid');
      await queue.recordRejection(
        entity: PendingEntity.customer,
        entityId: 'cus-1',
        refused: {'phone_number': '111'},
        rollback: RejectionRollback.restored,
      );
      await queue.markOutdated([outdated.id]);

      final [dropped, refused] = await sut.watchHistory().first;

      expect(refused.rejectedValues, {'phone_number': '111'});
      expect(refused.rollback, RejectionRollback.restored);
      expect(dropped.status, PendingStatus.outdated);
      expect(dropped.changedFields, ['name']);
    },
  );

  test('is empty when the driver has recorded nothing', () async {
    expect(await sut.watchHistory().first, isEmpty);
  });
}
