import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// Routes, matched by server id.
class RouteApplier implements PullApplier {
  RouteApplier(this._db);

  final AppDatabase _db;

  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final r in rows['routes'] ?? const <Json>[]) {
      await upsert(r, context);
    }
  }

  /// Stores [r] and returns its local id.
  Future<String> upsert(Json r, PullContext context) async {
    final serverId = r['id'] as int;
    final date = (r['date'] as String).substring(0, 10);
    final existing = await (_db.select(
      _db.routeTable,
    )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
    final fields = RouteTableCompanion(
      route_date: Value(date),
      status: Value(r['status'] as String?),
      enabled: enabledOf(r),
      serverId: Value(serverId),
    );
    final String routeId;
    if (existing == null) {
      routeId =
          (await _db.into(_db.routeTable).insertReturning(fields)).routeId;
    } else {
      await (_db.update(
        _db.routeTable,
      )..where((t) => t.routeId.equals(existing.routeId))).write(fields);
      routeId = existing.routeId;
    }
    context.ids.recordRoute(serverId, routeId);
    return routeId;
  }
}
