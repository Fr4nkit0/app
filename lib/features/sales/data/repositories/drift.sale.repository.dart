import 'package:drift/drift.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/data/repositories/sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';

class DriftSaleRepository implements SaleRepository {
  DriftSaleRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Sale>> watchAllSales() {
    final query = _db.select(_db.saleTable).join([
      innerJoin(
        _db.customerTable,
        _db.customerTable.customerId.equalsExp(_db.saleTable.customerId),
      ),
    ]);

    return query.watch().asyncMap((rows) async {
      final sales = <Sale>[];

      for (final row in rows) {
        final saleRow = row.readTable(_db.saleTable);
        final customerRow = row.readTable(_db.customerTable);

        final itemRows =
            await (_db.select(
              _db.saleItemTable,
            )..where((t) => t.saleId.equals(saleRow.saleId))).join([
              innerJoin(
                _db.productTable,
                _db.productTable.productId.equalsExp(
                  _db.saleItemTable.productId,
                ),
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
              price: pr.price,
              available: pr.stock,
            ),
            quantity: ir.quantity,
          );
        }).toList();

        sales.add(
          Sale(
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
          ),
        );
      }

      return sales;
    });
  }

  @override
  Future<Resource<void>> saveSale(Sale sale) async {
    try {
      await _db.transaction(() async {
        await _db
            .into(_db.saleTable)
            .insert(
              SaleTableCompanion.insert(
                saleId: Value(sale.id),
                customerId: sale.customer.id,
                totalAmount: sale.total,
                paymentMethod: sale.paymentMethod.name,
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
                ),
              );
        }
      });

      return const Resource.success(null);
    } catch (e) {
      return Resource.error(e is Exception ? e : Exception(e.toString()));
    }
  }
}
