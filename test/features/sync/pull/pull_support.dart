import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/pull/pull_applier.dart';
import 'package:app/features/sync/pull/server_ids.dart';
import 'package:app/features/sync/pull/unsent.dart';

AppDatabase memoryDatabase() => AppDatabase(NativeDatabase.memory());

/// The context of an incremental pull: ids resolve against stored rows.
Future<PullContext> pullContext(AppDatabase db) async =>
    PullContext(unsent: await Unsent.load(db), ids: ServerIds.stored(db));

/// The context of a bootstrap: ids resolve only within the same download.
Future<PullContext> bootstrapContext(AppDatabase db) async =>
    PullContext(unsent: await Unsent.load(db), ids: ServerIds.downloaded(db));

Future<String> seedCustomer(
  AppDatabase db, {
  required String id,
  int? serverId,
  String name = 'Ana',
}) async {
  await db
      .into(db.customerTable)
      .insert(
        CustomerTableCompanion.insert(
          customerId: Value(id),
          name: name,
          serverId: Value(serverId),
        ),
      );
  return id;
}

Future<String> seedProduct(
  AppDatabase db, {
  required String id,
  int? serverId,
  int stock = 0,
}) async {
  await db
      .into(db.productTable)
      .insert(
        ProductTableCompanion.insert(
          productId: Value(id),
          name: 'Water 20L',
          price: 100,
          stock: Value(stock),
          serverId: Value(serverId),
        ),
      );
  return id;
}

Future<String> seedRoute(
  AppDatabase db, {
  required String id,
  required int serverId,
  required String date,
}) async {
  await db
      .into(db.routeTable)
      .insert(
        RouteTableCompanion.insert(
          routeId: Value(id),
          route_date: date,
          serverId: Value(serverId),
        ),
      );
  return id;
}

Future<void> enqueueUnsent(AppDatabase db, PendingEntity entity, String id) =>
    DriftPendingChangeRepository(
      db,
    ).enqueue(entity: entity, entityId: id, action: PendingAction.update);

String dayOf(DateTime d) => dateOnly(d);
