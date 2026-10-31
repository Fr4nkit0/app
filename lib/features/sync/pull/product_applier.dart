import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// Products, matched by server id.
class ProductApplier implements PullApplier {
  ProductApplier(this._db);

  final AppDatabase _db;

  /// The pull carries the list price but no truck stock: the stock keeps its
  /// local value, and a row without a price keeps the stored one. Recorded
  /// sales keep the unit price they were made at.
  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final p in rows['products'] ?? const <Json>[]) {
      final serverId = p['id'] as int;
      final existing = await context.ids.product(serverId);
      final fields = ProductTableCompanion(
        name: Value(p['name'] as String),
        description: Value(p['description'] as String?),
        price: p['price'] == null
            ? const Value.absent()
            : Value(toDouble(p['price'])),
        containerTypeId: Value(p['container_type_id'] as int?),
        enabled: enabledOf(p),
        serverId: Value(serverId),
      );
      if (existing == null) {
        await _db
            .into(_db.productTable)
            .insert(
              fields.price.present
                  ? fields
                  : fields.copyWith(price: const Value(0)),
            );
      } else {
        await (_db.update(
          _db.productTable,
        )..where((t) => t.productId.equals(existing))).write(fields);
      }
    }
  }

  /// The bootstrap's products carry their price; the stock is the day's
  /// [truckInventory] unless unsent sales already discounted it locally.
  Future<void> applySnapshot(
    List<Json> products,
    List<Json> truckInventory,
    PullContext context,
  ) async {
    final stockByProduct = <int, int>{
      for (final i in truckInventory)
        i['product_id'] as int: toDouble(i['current_quantity']).round(),
    };
    for (final p in products) {
      final serverId = p['id'] as int;
      final stock = stockByProduct[serverId] ?? 0;
      final existing = await (_db.select(
        _db.productTable,
      )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
      if (existing == null) {
        final row = await _db
            .into(_db.productTable)
            .insertReturning(
              ProductTableCompanion.insert(
                name: p['name'] as String,
                description: Value(p['description'] as String?),
                price: p['price'] == null ? 0 : toDouble(p['price']),
                stock: Value(stock),
                containerTypeId: Value(p['container_type_id'] as int?),
                serverId: Value(serverId),
              ),
            );
        context.ids.recordProduct(serverId, row.productId);
      } else {
        await (_db.update(
          _db.productTable,
        )..where((t) => t.productId.equals(existing.productId))).write(
          ProductTableCompanion(
            name: Value(p['name'] as String),
            description: Value(p['description'] as String?),
            price: p['price'] == null
                ? const Value.absent()
                : Value(toDouble(p['price'])),
            stock: context.unsent.hasSales
                ? const Value.absent()
                : Value(stock),
            containerTypeId: Value(p['container_type_id'] as int?),
          ),
        );
        context.ids.recordProduct(serverId, existing.productId);
      }
    }
  }
}
