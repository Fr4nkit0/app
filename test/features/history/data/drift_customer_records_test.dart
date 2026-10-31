import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/history/data/repositories/history.repository.dart';
import 'package:app/features/history/domain/models/customer_record.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/sales/data/database/record_status.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';

/// Records as the bootstrap stores them: server ids, no pending changes.
Future<void> seedBootstrappedRecords(AppDatabase db) async {
  for (final (id, name) in [('cus-1', 'Sanatorio'), ('cus-2', 'Kiosco')]) {
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: Value(id),
            name: name,
            serverId: const Value(10),
          ),
        );
  }
  await db
      .into(db.productTable)
      .insert(
        ProductTableCompanion.insert(
          productId: const Value('p-1'),
          name: 'Agua 20L',
          price: 5200,
        ),
      );
  await db
      .into(db.routeTable)
      .insert(
        RouteTableCompanion.insert(
          routeId: const Value('r-1'),
          route_date: '2026-10-30',
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
          scheduledAt: DateTime(2026, 10, 30, 9),
        ),
      );
  await db
      .into(db.visitOutcomeTable)
      .insert(
        VisitOutcomeTableCompanion.insert(
          id: const Value(1),
          code: const Value('delivered'),
          name: 'Entregado',
        ),
      );
  await db
      .into(db.visitTable)
      .insert(
        VisitTableCompanion.insert(
          visitId: const Value('visit-19'),
          routeStopId: 'stop-1',
          customerId: 'cus-1',
          visitType: 'visit',
          outcomeId: const Value(1),
          observations: const Value('Dejó en portería'),
          arrived_at: DateTime(2026, 10, 30, 9),
          serverId: const Value(19),
        ),
      );
  Future<void> sale(
    String id,
    String customerId,
    double total,
    String method,
    DateTime date, {
    String status = RecordStatus.confirmed,
    int? serverId,
  }) => db
      .into(db.saleTable)
      .insert(
        SaleTableCompanion.insert(
          saleId: Value(id),
          customerId: customerId,
          totalAmount: total,
          paymentMethod: method,
          quantity: 8,
          shipping_amount: 0,
          saleDate: Value(date),
          status: Value(status),
          visitId: const Value('visit-19'),
          serverId: Value(serverId),
        ),
      );
  await sale(
    'sale-18',
    'cus-1',
    41600,
    'credit',
    DateTime(2026, 10, 30, 9, 5),
    serverId: 18,
  );
  await db
      .into(db.saleItemTable)
      .insert(
        SaleItemTableCompanion.insert(
          saleId: 'sale-18',
          productId: 'p-1',
          quantity: 8,
          unitPrice: 5200,
          subtotal: 41600,
        ),
      );
  await sale(
    'sale-cancelled',
    'cus-1',
    5200,
    'cash',
    DateTime(2026, 10, 30, 9, 15),
    status: RecordStatus.cancelled,
    serverId: 21,
  );
  await sale(
    'sale-other',
    'cus-2',
    1000,
    'cash',
    DateTime(2026, 10, 30, 9, 30),
  );
  await db
      .into(db.paymentTable)
      .insert(
        PaymentTableCompanion.insert(
          paymentId: const Value('pay-1'),
          customerId: 'cus-1',
          amount: 2000,
          paymentMethod: 'EFECTIVO',
          createdAt: Value(DateTime(2026, 10, 30, 9, 10)),
          serverId: const Value(7),
        ),
      );
  Future<void> movement(
    String id,
    DateTime createdAt, {
    String? reverses,
    String? saleId,
  }) => db
      .into(db.containerMovementTable)
      .insert(
        ContainerMovementTableCompanion.insert(
          containerMovementId: Value(id),
          customerId: 'cus-1',
          containerType: 'B20',
          deliveredQuantity: 8,
          returnedQuantity: 3,
          saleId: Value(saleId),
          reversesMovementId: Value(reverses),
          createdAt: Value(createdAt),
          serverId: const Value(30),
        ),
      );
  await movement('mov-1', DateTime(2026, 10, 30, 9, 6), saleId: 'sale-18');
  await movement(
    'mov-2',
    DateTime(2026, 10, 30, 9, 16),
    saleId: 'sale-cancelled',
  );
  await movement(
    'mov-2-reversal',
    DateTime(2026, 10, 30, 9, 20),
    reverses: 'mov-2',
    saleId: 'sale-cancelled',
  );
}

void main() {
  late AppDatabase db;
  late DriftHistoryRepository sut;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftHistoryRepository(db);
    await seedBootstrappedRecords(db);
  });

  tearDown(() => db.close());

  test('lists the bootstrapped records of the customer newest first, without '
      'reversals or other customers', () async {
    final records = await sut.watchCustomerRecords('cus-1').first;

    expect(records.map((r) => r.id), [
      'mov-2',
      'sale-cancelled',
      'pay-1',
      'mov-1',
      'sale-18',
      'visit-19',
    ]);
  });

  test('a visit carries its outcome and observations', () async {
    final visit = (await sut.watchCustomerRecords('cus-1').first).last;

    expect(visit.type, CustomerRecordType.visit);
    expect(visit.date, DateTime(2026, 10, 30, 9));
    expect(visit.outcomeName, 'Entregado');
    expect(visit.observations, 'Dejó en portería');
    expect(visit.isCancelled, isFalse);
  });

  test('a credit sale carries its total, method and items', () async {
    final sale = (await sut.watchCustomerRecords('cus-1').first).singleWhere(
      (r) => r.id == 'sale-18',
    );

    expect(sale.type, CustomerRecordType.sale);
    expect(sale.amount, 41600);
    expect(sale.saleMethod, PaymentMethod.credit);
    expect(sale.saleItems.single.productName, 'Agua 20L');
    expect(sale.saleItems.single.quantity, 8);
    expect(sale.isCancelled, isFalse);
  });

  test('a cancelled sale and its delivery are marked cancelled', () async {
    final records = await sut.watchCustomerRecords('cus-1').first;

    expect(
      records.singleWhere((r) => r.id == 'sale-cancelled').isCancelled,
      isTrue,
    );
    expect(records.singleWhere((r) => r.id == 'mov-2').isCancelled, isTrue);
  });

  test('a payment carries its amount and type', () async {
    final payment = (await sut.watchCustomerRecords('cus-1').first).singleWhere(
      (r) => r.id == 'pay-1',
    );

    expect(payment.type, CustomerRecordType.payment);
    expect(payment.amount, 2000);
    expect(payment.paymentType, PaymentType.cash);
    expect(payment.isCancelled, isFalse);
  });

  test('a container movement carries its type and quantities', () async {
    final movement = (await sut.watchCustomerRecords('cus-1').first)
        .singleWhere((r) => r.id == 'mov-1');

    expect(movement.type, CustomerRecordType.containerMovement);
    expect(movement.containerType, 'B20');
    expect(movement.deliveredQuantity, 8);
    expect(movement.returnedQuantity, 3);
  });

  test('emits again when a record of the customer is stored', () async {
    final emissions = sut.watchCustomerRecords('cus-2');
    final expectation = expectLater(
      emissions.map((records) => records.length),
      emitsInOrder([1, 2]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await db
        .into(db.paymentTable)
        .insert(
          PaymentTableCompanion.insert(
            customerId: 'cus-2',
            amount: 500,
            paymentMethod: 'TRANSFERENCIA',
          ),
        );

    await expectation;
  });

  test('a customer with no records gets an empty list', () async {
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const Value('cus-3'),
            name: 'Nuevo',
          ),
        );

    expect(await sut.watchCustomerRecords('cus-3').first, isEmpty);
  });
}
