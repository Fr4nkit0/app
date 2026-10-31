import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/usecases/cancel_payment.usecase.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/cancel_sale.usecase.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';
import 'package:app/features/sync/data/repositories/admin_cancellations.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/pull/cancellation_applier.dart';

import 'pull_support.dart';

void main() {
  late AppDatabase db;
  late DriftPendingChangeRepository queue;
  late CancellationApplier applier;

  final soldAt = DateTime.now();
  final cancelledAt = DateTime.utc(2026, 10, 31, 15, 30);
  final customer = Customer(
    id: 'c-1',
    name: 'Ana',
    addresses: const [],
    preferences: const [],
  );
  const water = Product(
    id: 'p-1',
    name: 'Water 20L',
    unitLabel: '',
    price: 100,
  );

  Future<double> balance() =>
      DriftPaymentRepository(db).watchCustomerBalance('c-1').first;

  Future<int> stock() async => (await (db.select(
    db.productTable,
  )..where((t) => t.productId.equals('p-1'))).getSingle()).stock;

  Future<SaleTableData> saleRow(String id) =>
      (db.select(db.saleTable)..where((t) => t.saleId.equals(id))).getSingle();

  Future<PaymentTableData> paymentRow(String id) => (db.select(
    db.paymentTable,
  )..where((t) => t.paymentId.equals(id))).getSingle();

  Future<List<PendingChange>> pending() => queue.getPending();

  /// Marks everything queued so far as accepted by the server.
  Future<void> pushAll() async =>
      queue.markSent([for (final c in await pending()) c.id]);

  /// An off-route cash sale of 3 waters made on the device and pushed.
  Future<Sale> sellOnDevice({
    String id = 'sale-1',
    int? serverId,
    List<ContainerMovement>? containers,
  }) async {
    final sale = Sale(
      id: id,
      customer: customer,
      items: const [SaleItem(product: water, quantity: 3)],
      total: 300,
      paymentMethod: PaymentMethod.cash,
      date: soldAt,
    );
    await RegisterSaleUseCase(
      saleRepo: DriftSaleRepository(db),
      paymentRepo: DriftPaymentRepository(db),
      inventoryRepo: DriftInventoryRepository(db),
      transaction: driftTransactionRunner(db),
    ).execute(sale, containerMovements: containers);
    if (serverId != null) {
      await (db.update(db.saleTable)..where((t) => t.saleId.equals(id))).write(
        SaleTableCompanion(serverId: Value(serverId)),
      );
    }
    await pushAll();
    return sale;
  }

  /// A credit sale of 2 waters the bootstrap brought: no client uuid of
  /// this device, the downloaded balance and stock already count it.
  Future<void> storeServerSale({
    required String id,
    required int serverId,
  }) async {
    await db
        .into(db.saleTable)
        .insert(
          SaleTableCompanion.insert(
            saleId: Value(id),
            customerId: 'c-1',
            totalAmount: 200,
            paymentMethod: PaymentMethod.credit.name,
            saleDate: Value(soldAt),
            quantity: 0,
            shipping_amount: 0,
            serverId: Value(serverId),
          ),
        );
    await db
        .into(db.saleItemTable)
        .insert(
          SaleItemTableCompanion.insert(
            saleId: id,
            productId: 'p-1',
            quantity: 2,
            unitPrice: 100,
            subtotal: 200,
          ),
        );
  }

  Future<void> payDebtOnDevice({String id = 'pay-1'}) async {
    await DriftPaymentRepository(db).recordPayment(
      Payment(
        id: id,
        customerId: 'c-1',
        amount: 250,
        type: PaymentType.cash,
        createdAt: soldAt,
      ),
    );
    await pushAll();
  }

  Map<String, dynamic> saleEvent({
    int saleId = 900,
    String? clientUuid,
    bool byAdmin = true,
    String? reason = 'Error de carga',
  }) => {
    'sale_id': saleId,
    'client_uuid': clientUuid,
    'cancelled_at': cancelledAt.toIso8601String(),
    'reason': reason,
    'cancelled_by_admin': byAdmin,
  };

  Map<String, dynamic> paymentEvent({
    int paymentId = 950,
    String? clientUuid,
    bool byAdmin = true,
  }) => {
    'payment_id': paymentId,
    'client_uuid': clientUuid,
    'cancelled_at': cancelledAt.toIso8601String(),
    'reason': 'Billete falso',
    'cancelled_by_admin': byAdmin,
  };

  Future<void> apply({
    List<Map<String, dynamic>> sales = const [],
    List<Map<String, dynamic>> payments = const [],
  }) async => db.transaction(
    () async => applier.applyChanges({
      'sale_cancellations': sales,
      'payment_cancellations': payments,
    }, await pullContext(db)),
  );

  setUp(() async {
    db = memoryDatabase();
    queue = DriftPendingChangeRepository(db);
    applier = CancellationApplier(db);
    await seedCustomer(db, id: 'c-1', serverId: 11);
    await seedProduct(db, id: 'p-1', serverId: 21, stock: 10);
    await db
        .into(db.customerBalanceTable)
        .insert(
          CustomerBalanceTableCompanion.insert(
            customerId: 'c-1',
            currentBalance: const Value(1000),
          ),
        );
  });
  tearDown(() => db.close());

  group('sale_cancellations', () {
    test('cancels a device sale found by client uuid: stock back to the '
        'truck, the sale out of the balance, its payment kept, nothing '
        'queued', () async {
      await sellOnDevice();
      expect(await stock(), 7);
      expect(await balance(), 1000);

      await apply(sales: [saleEvent(clientUuid: 'sale-1')]);

      final sale = await saleRow('sale-1');
      expect(sale.status, 'CANCELLED');
      expect(sale.cancelledAt, cancelledAt.toLocal());
      expect(sale.cancellationReason, 'Error de carga');
      // The server does not cancel a sale's payments with it; it reports
      // each one it cancels as its own event.
      final settling = (await db.select(db.paymentTable).get()).single;
      expect(settling.status, 'CONFIRMED');
      expect(await stock(), 10);
      expect(await balance(), 700);
      expect(await pending(), isEmpty);
      expect(await AdminCancellations(db).saleIds(), {'sale-1'});
    });

    test('the containers delivered with a cancelled sale leave custody '
        'once', () async {
      await sellOnDevice(
        containers: [
          ContainerMovement(
            id: 'mov-1',
            customerId: 'c-1',
            containerType: 'JUG',
            deliveredQuantity: 3,
            returnedQuantity: 1,
            createdAt: soldAt,
            saleId: 'sale-1',
          ),
        ],
      );
      Future<int> custody() async =>
          (await db.select(db.customerContainerBalanceTable).getSingle())
              .quantity;
      expect(await custody(), 2);

      await apply(sales: [saleEvent(clientUuid: 'sale-1')]);
      await apply(sales: [saleEvent(clientUuid: 'sale-1')]);

      expect(await custody(), 0);
      expect(await pending(), isEmpty);
    });

    test('cancels a server sale found by server id: its stock and its '
        'debt come back once', () async {
      await storeServerSale(id: 'srv-sale', serverId: 901);

      await apply(sales: [saleEvent(saleId: 901, byAdmin: false)]);

      expect((await saleRow('srv-sale')).status, 'CANCELLED');
      expect(await stock(), 12);
      expect(await balance(), 800);
      expect(await pending(), isEmpty);
      expect(await AdminCancellations(db).saleIds(), isEmpty);
    });

    test('a re-sent event changes nothing', () async {
      await storeServerSale(id: 'srv-sale', serverId: 901);

      await apply(sales: [saleEvent(saleId: 901)]);
      await apply(sales: [saleEvent(saleId: 901)]);

      expect(await stock(), 12);
      expect(await balance(), 800);
      final creditNotes = await (db.select(
        db.customerAccountEntryTable,
      )..where((t) => t.entryType.equals('CREDIT_NOTE'))).get();
      expect(creditNotes, hasLength(1));
      expect(await AdminCancellations(db).saleIds(), {'srv-sale'});
    });

    test('a sale already cancelled on the device and not yet pushed is not '
        'reversed again; its queued cancellation is settled', () async {
      await sellOnDevice(serverId: 900);
      await CancelSaleUseCase(
        saleRepo: DriftSaleRepository(db),
        paymentRepo: DriftPaymentRepository(db),
        inventoryRepo: DriftInventoryRepository(db),
        transaction: driftTransactionRunner(db),
      ).execute('sale-1');
      expect(await stock(), 10);
      expect(await balance(), 1000);
      expect(
        (await pending()).map((c) => c.entity),
        contains(PendingEntity.saleCancellation),
      );

      await apply(sales: [saleEvent(saleId: 900, clientUuid: 'sale-1')]);

      expect(await stock(), 10);
      expect(await balance(), 1000);
      // The server already holds the sale's cancellation; it no longer
      // counts as unsent, so the next reconciliation does not take it out
      // twice. The cancellation of its payment still goes to the server.
      expect((await pending()).map((c) => c.entity), [
        PendingEntity.paymentCancellation,
      ]);
      expect(await AdminCancellations(db).saleIds(), {'sale-1'});
    });

    test('an event for a sale not on the device is ignored', () async {
      await sellOnDevice();

      await apply(sales: [saleEvent(saleId: 999, clientUuid: 'unknown')]);

      expect((await saleRow('sale-1')).status, 'CONFIRMED');
      expect(await stock(), 7);
      expect(await balance(), 1000);
      expect(await AdminCancellations(db).saleIds(), isEmpty);
    });
  });

  group('payment_cancellations', () {
    test('cancels a device payment found by client uuid: its amount goes '
        'back on the balance, nothing queued', () async {
      await payDebtOnDevice();
      expect(await balance(), 750);

      await apply(payments: [paymentEvent(clientUuid: 'pay-1')]);

      final payment = await paymentRow('pay-1');
      expect(payment.status, 'CANCELLED');
      expect(payment.cancelledAt, cancelledAt.toLocal());
      expect(payment.cancellationReason, 'Billete falso');
      expect(await balance(), 1000);
      expect(await pending(), isEmpty);
      expect(await AdminCancellations(db).paymentIds(), {'pay-1'});
    });

    test('cancels a server payment found by server id once, even when the '
        'event is re-sent', () async {
      await db
          .into(db.paymentTable)
          .insert(
            PaymentTableCompanion.insert(
              paymentId: const Value('srv-pay'),
              customerId: 'c-1',
              amount: 400,
              paymentMethod: PaymentType.cash.dbValue,
              createdAt: Value(soldAt),
              serverId: const Value(951),
            ),
          );

      await apply(payments: [paymentEvent(paymentId: 951, byAdmin: false)]);
      await apply(payments: [paymentEvent(paymentId: 951, byAdmin: false)]);

      expect((await paymentRow('srv-pay')).status, 'CANCELLED');
      expect(await balance(), 1400);
      expect(await pending(), isEmpty);
      expect(await AdminCancellations(db).paymentIds(), isEmpty);
    });

    test('a payment already cancelled on the device and not yet pushed is '
        'not reversed again', () async {
      await payDebtOnDevice();
      await CancelPaymentUseCase(
        paymentRepo: DriftPaymentRepository(db),
        transaction: driftTransactionRunner(db),
      ).execute('pay-1');
      expect(await balance(), 1000);

      await apply(payments: [paymentEvent(clientUuid: 'pay-1')]);

      expect(await balance(), 1000);
      expect(await pending(), isEmpty);
    });

    test('an event for a payment not on the device is ignored', () async {
      await payDebtOnDevice();

      await apply(payments: [paymentEvent(paymentId: 999)]);

      expect((await paymentRow('pay-1')).status, 'CONFIRMED');
      expect(await balance(), 750);
    });
  });
}
