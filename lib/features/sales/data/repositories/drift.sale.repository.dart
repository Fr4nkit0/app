import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/payments/data/repositories/customer_account.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/data/database/record_status.dart';
import 'package:app/features/sales/data/repositories/sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

class DriftSaleRepository implements SaleRepository {
  DriftSaleRepository(AppDatabase db)
    : _db = db,
      _queue = DriftPendingChangeRepository(db),
      _account = CustomerAccount(db);

  final AppDatabase _db;
  final PendingChangeRepository _queue;
  final CustomerAccount _account;

  @override
  Stream<List<Sale>> watchVisitSales(String visitId) =>
      _salesQuery(_db.saleTable.visitId.equals(visitId)).watch().asyncMap(
        (rows) async => [for (final row in rows) await _toSale(row)],
      );

  @override
  Future<Sale?> findSale(String saleId) async {
    final row = await _salesQuery(
      _db.saleTable.saleId.equals(saleId),
    ).getSingleOrNull();
    return row == null ? null : _toSale(row);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _salesQuery(
    Expression<bool> where,
  ) => _db.select(_db.saleTable).join([
    innerJoin(
      _db.customerTable,
      _db.customerTable.customerId.equalsExp(_db.saleTable.customerId),
    ),
  ])..where(where);

  Future<Sale> _toSale(TypedResult row) async {
    final saleRow = row.readTable(_db.saleTable);
    final customerRow = row.readTable(_db.customerTable);

    final itemRows =
        await (_db.select(
          _db.saleItemTable,
        )..where((t) => t.saleId.equals(saleRow.saleId))).join([
          innerJoin(
            _db.productTable,
            _db.productTable.productId.equalsExp(_db.saleItemTable.productId),
          ),
        ]).get();

    final items = itemRows.map((itemRow) {
      final ir = itemRow.readTable(_db.saleItemTable);
      final pr = itemRow.readTable(_db.productTable);
      return SaleItem(
        product: Product(
          id: pr.productId,
          name: pr.name,
          unitLabel: '',
          // The price the sale was made at, not today's list price.
          price: ir.unitPrice,
          available: pr.stock,
          agreementId: ir.agreementServerId,
          agreementUuid: ir.agreementUuid,
        ),
        quantity: ir.quantity,
      );
    }).toList();

    return Sale(
      id: saleRow.saleId,
      customer: Customer(
        id: customerRow.customerId,
        name: customerRow.name,
        addresses: const [],
        preferences: const [],
        productLabels: const [],
      ),
      items: items,
      total: saleRow.totalAmount,
      paymentMethod: PaymentMethod.values.firstWhere(
        (m) => m.name == saleRow.paymentMethod,
        orElse: () => PaymentMethod.cash,
      ),
      date: saleRow.saleDate,
      cashAmount: saleRow.cashAmount,
      transferAmount: saleRow.transferAmount,
      visitId: saleRow.visitId,
      isCancelled: saleRow.status == RecordStatus.cancelled,
    );
  }

  @override
  Future<void> saveSale(Sale sale) async {
    await _db
        .into(_db.saleTable)
        .insert(
          SaleTableCompanion.insert(
            saleId: Value(sale.id),
            customerId: sale.customer.id,
            totalAmount: sale.total,
            paymentMethod: sale.paymentMethod.name,
            saleDate: Value(sale.date),
            quantity: 0,
            shipping_amount: 0,
            visitId: Value(sale.visitId),
            cashAmount: Value(sale.cashAmount),
            transferAmount: Value(sale.transferAmount),
          ),
        );

    for (final item in sale.items) {
      await _db
          .into(_db.saleItemTable)
          .insert(
            SaleItemTableCompanion.insert(
              saleId: sale.id,
              productId: item.product.id,
              quantity: item.quantity,
              unitPrice: item.product.price,
              subtotal: item.subtotal,
              agreementServerId: Value(item.product.agreementId),
              agreementUuid: Value(item.product.agreementUuid),
            ),
          );
      // The truck stock drops locally until the next download; like the
      // server, it has no floor.
      await _moveStock(item.product.id, -item.quantity);
    }

    // The server books every sale on the customer's account; a sale
    // paid on the spot is settled by the payments linked to it.
    final entryId = const Uuid().v4();
    final isCredit = sale.paymentMethod == PaymentMethod.credit;
    await _db
        .into(_db.customerAccountEntryTable)
        .insert(
          CustomerAccountEntryTableCompanion.insert(
            customerAccountEntryId: Value(entryId),
            customerId: sale.customer.id,
            saleId: Value(sale.id),
            entryType: 'SALE',
            amount: sale.total,
            direction: 1,
            createdAt: Value(sale.date),
            description: Value(isCredit ? 'Credit sale' : 'Sale'),
          ),
        );
    await _account.post(sale.customer.id, sale.total, lastEntryId: entryId);

    await _queue.enqueue(
      entity: PendingEntity.sale,
      entityId: sale.id,
      action: PendingAction.insert,
      payload: {
        'saleId': sale.id,
        'customerId': sale.customer.id,
        'total': sale.total,
        'paymentMethod': sale.paymentMethod.name,
        'cashAmount': sale.cashAmount,
        'transferAmount': sale.transferAmount,
        'visitId': sale.visitId,
        'date': sale.date.toIso8601String(),
        'items': [
          for (final item in sale.items)
            {
              'productId': item.product.id,
              'quantity': item.quantity,
              'unitPrice': item.product.price,
              'agreementId': item.product.agreementId,
              'agreementUuid': item.product.agreementUuid,
              'subtotal': item.subtotal,
            },
        ],
      },
    );
  }

  @override
  Future<void> cancelSale(
    Sale sale, {
    required DateTime at,
    String? reason,
  }) async {
    await (_db.update(
      _db.saleTable,
    )..where((t) => t.saleId.equals(sale.id))).write(
      SaleTableCompanion(
        status: const Value(RecordStatus.cancelled),
        cancelledAt: Value(at),
        cancellationReason: Value(reason),
        lastModifiedDate: Value(at),
      ),
    );
    await _returnStock(sale.id, 1);

    // Like the server: a credit note takes the whole sale back out of the
    // account; the payments that settled it are cancelled on their own.
    final entryId = const Uuid().v4();
    await _db
        .into(_db.customerAccountEntryTable)
        .insert(
          CustomerAccountEntryTableCompanion.insert(
            customerAccountEntryId: Value(entryId),
            customerId: sale.customer.id,
            saleId: Value(sale.id),
            entryType: creditNoteEntry,
            amount: sale.total,
            direction: -1,
            createdAt: Value(at),
            description: const Value('Sale cancelled'),
          ),
        );
    await _account.post(sale.customer.id, -sale.total, lastEntryId: entryId);

    await _queue.enqueue(
      entity: PendingEntity.saleCancellation,
      entityId: sale.id,
      action: PendingAction.insert,
      payload: {
        'saleId': sale.id,
        'cancelledAt': at.toIso8601String(),
        'reason': reason,
      },
    );
  }

  /// Takes back a cancellation the server refused: the sale counts again,
  /// in the balance and in the truck stock. Nothing is queued.
  Future<void> undoCancellation(String saleId) async {
    final sale = await (_db.select(
      _db.saleTable,
    )..where((t) => t.saleId.equals(saleId))).getSingleOrNull();
    if (sale == null || sale.status != RecordStatus.cancelled) return;
    await (_db.update(
      _db.saleTable,
    )..where((t) => t.saleId.equals(saleId))).write(
      SaleTableCompanion(
        status: const Value(RecordStatus.confirmed),
        cancelledAt: const Value(null),
        cancellationReason: const Value(null),
        lastModifiedDate: Value(DateTime.now()),
      ),
    );
    await _returnStock(saleId, -1);
    await (_db.delete(_db.customerAccountEntryTable)..where(
          (t) =>
              t.saleId.equals(saleId) & t.entryType.equals(creditNoteEntry),
        ))
        .go();
    await _account.post(sale.customerId, sale.totalAmount);
  }

  static const creditNoteEntry = 'CREDIT_NOTE';

  /// Moves the truck stock of every line of [saleId] back ([sign] 1) or out
  /// again ([sign] -1).
  Future<void> _returnStock(String saleId, int sign) async {
    final lines = await (_db.select(
      _db.saleItemTable,
    )..where((t) => t.saleId.equals(saleId))).get();
    for (final line in lines) {
      await _moveStock(line.productId, sign * line.quantity);
    }
  }

  Future<void> _moveStock(String productId, int delta) =>
      (_db.update(
        _db.productTable,
      )..where((t) => t.productId.equals(productId))).write(
        ProductTableCompanion.custom(
          stock: _db.productTable.stock + Variable(delta),
        ),
      );
}
