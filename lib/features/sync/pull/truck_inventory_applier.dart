import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// What the truck carries on each route.
class TruckInventoryApplier implements PullApplier {
  TruckInventoryApplier(this._db, {required DateTime Function() today})
    : _today = today;

  final AppDatabase _db;
  final DateTime Function() _today;

  /// Truck stock follows today's route inventory unless unsent sales already
  /// discounted it locally.
  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final i in rows['route_inventories'] ?? const <Json>[]) {
      final route = await context.ids.route(i['route_id'] as int?);
      final productId = await context.ids.product(i['product_id'] as int?);
      if (route == null || productId == null) continue;
      final serverId = i['id'] as int;
      final quantity = toDouble(i['current_quantity']).round();
      final fields = RouteInventoryLoadTableCompanion(
        routeId: Value(route.routeId),
        productId: Value(productId),
        quantity: Value(quantity),
        enabled: enabledOf(i),
        serverId: Value(serverId),
      );
      final updated = await (_db.update(
        _db.routeInventoryLoadTable,
      )..where((t) => t.serverId.equals(serverId))).write(fields);
      if (updated == 0) {
        await _db.into(_db.routeInventoryLoadTable).insert(fields);
      }

      if (route.route_date == dateOnly(_today()) && !context.unsent.hasSales) {
        await (_db.update(_db.productTable)
              ..where((t) => t.productId.equals(productId)))
            .write(ProductTableCompanion(stock: Value(quantity)));
      }
    }
  }

  /// The bootstrap carries the whole load of [routeId]: its server rows are
  /// replaced, the ones only on the device stay. The truck stock itself is
  /// set with the products ([ProductApplier.applySnapshot]).
  Future<void> replaceRoute(
    String routeId,
    List<Json> items,
    PullContext context,
  ) async {
    await (_db.delete(
      _db.routeInventoryLoadTable,
    )..where((t) => t.routeId.equals(routeId) & t.serverId.isNotNull())).go();
    for (final i in items) {
      final productId = await context.ids.product(i['product_id'] as int);
      if (productId == null) continue;
      await _db
          .into(_db.routeInventoryLoadTable)
          .insert(
            RouteInventoryLoadTableCompanion.insert(
              routeId: routeId,
              productId: productId,
              quantity: toDouble(i['current_quantity']).round(),
              serverId: Value(i['id'] as int),
            ),
          );
    }
  }
}
