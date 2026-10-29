import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../pull/pull_applier.dart' show dateOnly;
import 'entity_pusher.dart';

/// A reference between pushed records: the server id once the referenced
/// record has one, its client uuid otherwise (the server resolves it within
/// the same request, which it processes in dependency order).
Json reference(String name, {required int? serverId, required String uuid}) =>
    serverId != null ? {'${name}_id': serverId} : {'${name}_uuid': uuid};

/// The visit screen links movements, sales and payments to the stop being
/// visited rather than to the visit, which is recorded when the visit ends;
/// resolves [id] (a visit or a stop) to the recorded visit, or null when
/// the record travels without a link.
Future<VisitTableData?> resolveVisit(AppDatabase db, String? id) async {
  if (id == null) return null;
  final direct = await (db.select(
    db.visitTable,
  )..where((t) => t.visitId.equals(id))).getSingleOrNull();
  if (direct != null) return direct;
  final ofStop =
      await (db.select(db.visitTable)
            ..where((t) => t.routeStopId.equals(id))
            ..orderBy([(t) => OrderingTerm.desc(t.arrived_at)])
            ..limit(1))
          .get();
  return ofStop.isEmpty ? null : ofStop.first;
}

/// Whether [id] names a stop of [today]'s route that is still pending with
/// no visit recorded: its visit is open. Records linked to it wait in the
/// outbox, since the server only takes the visit link on insert and a
/// record sent before its visit would lose it for good. A stop of another
/// day does not hold them: that visit will not be closed any more.
Future<bool> awaitsOpenVisit(
  AppDatabase db,
  String? id, {
  required DateTime today,
}) async {
  if (id == null || await resolveVisit(db, id) != null) return false;
  final row = await (db.select(db.routeStopTable).join([
    innerJoin(
      db.routeTable,
      db.routeTable.routeId.equalsExp(db.routeStopTable.routeId),
    ),
  ])..where(db.routeStopTable.routeStopId.equals(id))).getSingleOrNull();
  if (row == null) return false;
  return row.readTable(db.routeStopTable).status == 'pending' &&
      row.readTable(db.routeTable).route_date == dateOnly(today);
}

/// The customer reference of a record of [customerId].
Future<Json> customerReference(AppDatabase db, String customerId) async {
  final customer = await (db.select(
    db.customerTable,
  )..where((t) => t.customerId.equals(customerId))).getSingleOrNull();
  return reference('customer', serverId: customer?.serverId, uuid: customerId);
}
