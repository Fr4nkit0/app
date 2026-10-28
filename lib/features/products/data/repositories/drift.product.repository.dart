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

  static Product _toProduct(ProductTableData row) => Product(
    id: row.productId,
    name: row.name,
    unitLabel: row.description ?? '', // Using description as unitLabel mapping
    price: row.price,
    available: row.stock,
  );

  @override
  Stream<List<Product>> watchAllProducts() {
    return _enabled.watch().map((rows) => rows.map(_toProduct).toList());
  }

  @override
  Stream<List<Product>> watchProductsFor(String customerId, {DateTime? day}) {
    final agreements = db.select(db.customerAgreementTable)
      ..where((t) => t.customerId.equals(customerId) & t.enabled.equals(true));
    // Re-emits when either products or agreements change.
    final changes = db.customSelect(
      'SELECT 1',
      readsFrom: {db.productTable, db.customerAgreementTable},
    ).watch();
    return changes.asyncMap((_) async {
      final products = (await _enabled.get()).map(_toProduct);
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
