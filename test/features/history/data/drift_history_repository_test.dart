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
    await db.into(db.productTable).insert(
          ProductTableCompanion.insert(
            productId: const Value('p-1'),
            name: 'Agua 20L',
            price: 1500,
          ),
        );
    await db.into(db.customerAgreementTable).insert(
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

  test('is empty when the driver has recorded nothing', () async {
    expect(await sut.watchHistory().first, isEmpty);
  });
}
