import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// Containers loaded onto the truck of each dispatched route.
///
/// The server only appends loads and corrections, and its download windows
/// overlap, so a row may arrive more than once: each one is stored by its
/// server id, replacing the copy already on the device. A load whose route
/// or container type the device does not know is dropped.
class TruckContainerLoadApplier implements PullApplier {
  TruckContainerLoadApplier(this._db);

  final AppDatabase _db;

  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) => store(rows['route_container_loads'] ?? const <Json>[], context);

  /// Stores [loads]; the bootstrap passes `truck_container_loads`.
  Future<void> store(List<Json> loads, PullContext context) async {
    for (final l in loads) {
      final route = await context.ids.route(l['route_id'] as int?);
      final code = await context.ids.containerType(
        l['container_type_id'] as int?,
      );
      if (route == null || code == null) continue;
      await _db
          .into(_db.routeContainerLoadTable)
          .insertOnConflictUpdate(
            RouteContainerLoadTableCompanion.insert(
              id: Value(l['id'] as int),
              routeId: route.routeId,
              containerType: code,
              quantity: (l['quantity'] as num).toInt(),
              type: l['type'] as String,
              reason: Value(l['reason'] as String?),
              loadedAt: DateTime.parse(l['loaded_at'] as String).toLocal(),
            ),
          );
    }
  }
}
