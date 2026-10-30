import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/pull/stop_applier.dart';

import 'pull_support.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = memoryDatabase();
    await seedCustomer(db, id: 'cust-1', serverId: 11);
    await seedRoute(db, id: 'route-1', serverId: 7, date: '2026-10-19');
  });
  tearDown(() => db.close());

  Map<String, dynamic> stop({
    required int id,
    String? clientUuid,
    int routeId = 7,
    int customerId = 11,
    String status = 'PENDING',
    int? rescheduledFrom,
  }) => {
    'id': id,
    'client_uuid': clientUuid,
    'route_id': routeId,
    'customer_id': customerId,
    'address_id': null,
    'scheduled_time': '09:30:00',
    'is_rescheduled_from': rescheduledFrom,
    'status': status,
  };

  Future<void> seedStop(String id, {int? serverId, int sequence = 1}) => db
      .into(db.routeStopTable)
      .insert(
        RouteStopTableCompanion.insert(
          routeStopId: Value(id),
          routeId: 'route-1',
          customerId: 'cust-1',
          sequence: sequence,
          scheduledAt: DateTime(2026, 10, 19),
          serverId: Value(serverId),
        ),
      );

  Future<RouteStopTableData> stopWithServerId(int serverId) => (db.select(
    db.routeStopTable,
  )..where((t) => t.serverId.equals(serverId))).getSingle();

  group('pull', () {
    test(
      'adds a new stop at the end of its route and links one created on the device',
      () async {
        await seedStop('stop-1', serverId: 71, sequence: 1);
        await seedStop('stop-uuid', sequence: 2);

        await StopApplier(db).applyChanges({
          'route_stops': [
            stop(id: 72, clientUuid: 'stop-uuid', status: 'FINISHED'),
            stop(id: 73),
          ],
        }, await pullContext(db));

        final linked = await stopWithServerId(72);
        expect(linked.routeStopId, 'stop-uuid');
        expect(linked.status, 'done');
        expect(linked.sequence, 2);
        expect((await stopWithServerId(73)).sequence, 3);
      },
    );

    test('keeps a stop with an unsent change', () async {
      await seedStop('stop-1', serverId: 71);
      await enqueueUnsent(db, PendingEntity.routeStop, 'stop-1');

      await StopApplier(db).applyChanges({
        'route_stops': [stop(id: 71, status: 'FINISHED')],
      }, await pullContext(db));

      expect((await stopWithServerId(71)).status, 'pending');
    });

    test('marks a requested visit, clears the mark and leaves it when the '
        'server sends no mark', () async {
      await seedStop('stop-1', serverId: 71);

      await StopApplier(db).applyChanges({
        'route_stops': [
          {
            ...stop(id: 71),
            'is_requested': true,
            'note': 'Llamar antes',
            'scheduled_visit_id': 5,
          },
        ],
      }, await pullContext(db));
      var row = await stopWithServerId(71);
      expect(row.isRequested, isTrue);
      expect(row.note, 'Llamar antes');
      expect(row.scheduledVisitId, 5);

      // An older server sends no mark: the stored one stays.
      await StopApplier(db).applyChanges({
        'route_stops': [stop(id: 71, status: 'FINISHED')],
      }, await pullContext(db));
      row = await stopWithServerId(71);
      expect(row.status, 'done');
      expect(row.isRequested, isTrue);
      expect(row.note, 'Llamar antes');
      expect(row.scheduledVisitId, 5);

      // The admin cancelled the visit on a preference stop.
      await StopApplier(db).applyChanges({
        'route_stops': [
          {
            ...stop(id: 71),
            'is_requested': false,
            'note': null,
            'scheduled_visit_id': null,
          },
        ],
      }, await pullContext(db));
      row = await stopWithServerId(71);
      expect(row.isRequested, isFalse);
      expect(row.note, isNull);
      expect(row.scheduledVisitId, isNull);
    });

    test('disables a stop created only for a cancelled visit', () async {
      await StopApplier(db).applyChanges({
        'route_stops': [
          {
            ...stop(id: 73),
            'is_requested': true,
            'note': 'Dejar en portería',
            'scheduled_visit_id': 6,
          },
        ],
      }, await pullContext(db));
      expect((await stopWithServerId(73)).enabled, isTrue);

      await StopApplier(db).applyChanges({
        'route_stops': [
          {...stop(id: 73), 'enabled': false},
        ],
      }, await pullContext(db));

      expect((await stopWithServerId(73)).enabled, isFalse);
    });

    test('a new stop without a mark is not requested', () async {
      await StopApplier(db).applyChanges({
        'route_stops': [stop(id: 73)],
      }, await pullContext(db));

      final row = await stopWithServerId(73);
      expect(row.isRequested, isFalse);
      expect(row.note, isNull);
      expect(row.scheduledVisitId, isNull);
    });

    test('skips a stop whose route or customer is not on the device', () async {
      await StopApplier(db).applyChanges({
        'route_stops': [
          stop(id: 74, routeId: 99),
          stop(id: 75, customerId: 99),
        ],
      }, await pullContext(db));

      expect(await db.select(db.routeStopTable).get(), isEmpty);
    });
  });

  group('bootstrap', () {
    test(
      'orders the stops as downloaded and links reschedules within the download',
      () async {
        final context = await bootstrapContext(db);
        context.ids.recordCustomer(11, 'cust-1');

        await StopApplier(db).replaceRoute('route-1', [
          stop(id: 72),
          stop(id: 71, rescheduledFrom: 72),
        ], context);

        final first = await stopWithServerId(72);
        final second = await stopWithServerId(71);
        expect(first.sequence, 1);
        expect(second.sequence, 2);
        expect(second.rescheduledFromStopId, first.routeStopId);
        expect(await context.ids.stop(71), second.routeStopId);
      },
    );

    test('stores the requested visit mark and its note', () async {
      final context = await bootstrapContext(db);
      context.ids.recordCustomer(11, 'cust-1');

      await StopApplier(db).replaceRoute('route-1', [
        {...stop(id: 71), 'is_requested': true, 'note': 'Tocar timbre 2'},
        {...stop(id: 72), 'is_requested': false, 'note': null},
        stop(id: 73),
      ], context);

      final requested = await stopWithServerId(71);
      expect(requested.isRequested, isTrue);
      expect(requested.note, 'Tocar timbre 2');
      for (final id in [72, 73]) {
        final row = await stopWithServerId(id);
        expect(row.isRequested, isFalse);
        expect(row.note, isNull);
      }
    });

    test('skips a stop whose customer is not in the same download', () async {
      await StopApplier(
        db,
      ).replaceRoute('route-1', [stop(id: 71)], await bootstrapContext(db));

      expect(await db.select(db.routeStopTable).get(), isEmpty);
    });
  });
}
