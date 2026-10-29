import 'package:app/features/inventory/domain/legacy_container_type.dart';
import 'package:app/features/products/data/repositories/product.repository.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriftProductRepository implements ProductRepository {
  final AppDatabase db;

  DriftProductRepository(this.db);

  SimpleSelectStatement<$ProductTableTable, ProductTableData> get _enabled =>
      db.select(db.productTable)..where((t) => t.enabled.equals(true));

  static Product _toProduct(ProductTableData row, Map<int, String> codes) =>
      Product(
        id: row.productId,
        name: row.name,
        unitLabel: row.description ?? '', // Using description as unitLabel mapping
        price: row.price,
        available: row.stock,
        containerType:
            codes[row.containerTypeId] ?? legacyContainerCodeFromName(row.name),
      );

  /// Enabled products with their container type resolved from the catalog.
  Future<List<Product>> _loadProducts() async {
    final codes = {
      for (final t in await db.select(db.containerTypeTable).get()) t.id: t.code,
    };
    return [for (final row in await _enabled.get()) _toProduct(row, codes)];
  }

  @override
  Stream<List<Product>> watchAllProducts() {
    // Re-emits when either products or the container catalog change.
    return db
        .customSelect(
          'SELECT 1',
          readsFrom: {db.productTable, db.containerTypeTable},
        )
        .watch()
        .asyncMap((_) => _loadProducts());
  }

  @override
  Stream<List<Product>> watchProductsFor(String customerId, {DateTime? day}) {
    final agreements = db.select(db.customerAgreementTable)
      ..where((t) => t.customerId.equals(customerId) & t.enabled.equals(true));
    // Re-emits when products, agreements or the container catalog change.
    final changes = db.customSelect(
      'SELECT 1',
      readsFrom: {
        db.productTable,
        db.customerAgreementTable,
        db.containerTypeTable,
      },
    ).watch();
    return changes.asyncMap((_) async {
      final products = await _loadProducts();
      final today = _dateOnly(day ?? DateTime.now());
      // Server dates may come as full timestamps; only the day counts.
      bool inForce(CustomerAgreementTableData a) =>
          a.validFrom.substring(0, 10).compareTo(today) <= 0 &&
          (a.validTo == null || a.validTo!.substring(0, 10).compareTo(today) >= 0);
      final byProduct = <String, CustomerAgreementTableData>{};
      for (final a in (await agreements.get()).where(inForce)) {
        final current = byProduct[a.productId];
        // Two overlapping agreements: the most recent one wins.
        if (current == null || _wins(a, current)) {
          byProduct[a.productId] = a;
        }
      }
      return [
        for (final p in products)
          if (byProduct[p.id] case final a?)
            Product(
              id: p.id,
              name: p.name,
              unitLabel: p.unitLabel,
              price: a.unitPrice,
              available: p.available,
              containerType: p.containerType,
              agreementId: a.serverId,
              agreementUuid: a.agreementId,
            )
          else
            p,
      ];
    });
  }

  /// The server's rule: latest valid_from, then highest server id. An
  /// agreement not synced yet counts as the highest, since the server will
  /// give it the next id.
  static bool _wins(
    CustomerAgreementTableData a,
    CustomerAgreementTableData current,
  ) {
    final byDate = a.validFrom
        .substring(0, 10)
        .compareTo(current.validFrom.substring(0, 10));
    if (byDate != 0) return byDate > 0;
    if (a.serverId == null) return current.serverId != null;
    return current.serverId != null && a.serverId! > current.serverId!;
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final driftProductRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftProductRepository(db);
});
