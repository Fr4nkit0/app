import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../core/services/database.helper.dart';
import 'data/repositories/pending_change.repository.dart';
import 'data/repositories/server_shadow.dart';
import 'domain/models/pending_change.dart';
import 'domain/models/sync_status.dart';
import 'pull/pull_applier.dart' show dateOnly;
import 'push/agreement_pusher.dart';
import 'push/container_movement_pusher.dart';
import 'push/customer_address_pusher.dart';
import 'push/customer_preference_pusher.dart';
import 'push/customer_pusher.dart';
import 'push/entity_pusher.dart';
import 'push/payment_cancellation_pusher.dart';
import 'push/payment_pusher.dart';
import 'push/route_stop_pusher.dart';
import 'push/sale_cancellation_pusher.dart';
import 'push/sale_pusher.dart';
import 'push/visit_pusher.dart';
import 'sync_service.dart';

/// Runs the sync cycle: push every pending change in queue order, then
/// download (bootstrap when the local day is missing, pull otherwise).
///
/// Only one cycle runs at a time: a trigger that fires while a cycle is in
/// flight joins it instead of starting another one.
class SyncEngine {
  SyncEngine({
    required Dio dio,
    required AppDatabase db,
    required SyncService sync,
    List<EntityPusher>? pushers,
    DateTime Function()? now,
  }) : _dio = dio,
       _db = db,
       _sync = sync,
       _queue = DriftPendingChangeRepository(db),
       _shadow = ServerShadow(db),
       _pushers = pushers ?? defaultPushers(db, today: now ?? DateTime.now),
       _now = now ?? DateTime.now;

  static const lastCycleAtKey = 'last_cycle_at';
  static const lastCycleResultKey = 'last_cycle_result';
  static const lastCycleErrorKey = 'last_cycle_error';

  /// Review reason of an edit of a customer assigned to another driver: the
  /// server applied nothing and holds it for the admin's approval.
  static const foreignCustomerReason =
      'Customer is assigned to another driver.';

  /// The same reason as the server labels it since it answers in Spanish;
  /// the English key is kept for servers that predate the translation.
  static const foreignCustomerReasons = {
    foreignCustomerReason,
    'El cliente está asignado a otro repartidor.',
  };

  /// Entities whose edits of another driver's customer wait for approval;
  /// sales and payments of that customer are still applied and only
  /// flagged.
  static const _approvalEntities = {
    PendingEntity.customer,
    PendingEntity.customerAddress,
    PendingEntity.customerPreference,
  };

  /// Entity pushers in the server's dependency order.
  static List<EntityPusher> defaultPushers(
    AppDatabase db, {
    DateTime Function()? today,
  }) => [
    CustomerPusher(db),
    CustomerAddressPusher(db),
    CustomerPreferencePusher(db),
    AgreementPusher(db),
    RouteStopPusher(db),
    VisitPusher(db),
    // Before the movements, so a movement made with a sale finds it.
    SalePusher(db, today: today),
    ContainerMovementPusher(db, today: today),
    PaymentPusher(db, today: today),
    SaleCancellationPusher(db, today: today),
    PaymentCancellationPusher(db, today: today),
  ];

  final Dio _dio;
  final AppDatabase _db;
  final SyncService _sync;
  final PendingChangeRepository _queue;
  final ServerShadow _shadow;
  final List<EntityPusher> _pushers;
  final DateTime Function() _now;
  final _running = StreamController<bool>.broadcast();
  Future<SyncStatus>? _inFlight;

  bool get isRunning => _inFlight != null;

  /// Emits the current running flag and every later change.
  Stream<bool> watchRunning() async* {
    yield isRunning;
    yield* _running.stream;
  }

  /// Runs one cycle, or joins the one already running. Never throws: a
  /// failure is recorded in the returned status.
  Future<SyncStatus> runCycle() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    _running.add(true);
    final cycle = _cycle().whenComplete(() {
      _inFlight = null;
      _running.add(false);
    });
    _inFlight = cycle;
    return cycle;
  }

  Future<SyncStatus> _cycle() async {
    try {
      await push();
      if (await _sync.needsBootstrap()) {
        await _sync.bootstrap();
      } else {
        await _sync.pull();
      }
      await _recordCycle(SyncCycleResult.success, null);
    } catch (e) {
      if (_isOffline(e)) {
        await _recordCycle(SyncCycleResult.offline, null);
      } else {
        await _recordCycle(SyncCycleResult.failure, _describe(e));
      }
    }
    return status();
  }

  /// Sends every pending change in one request. Queue entries change state
  /// only after the server answered: a cut before the answer leaves them
  /// pending, and the retry carries the same client uuids, which the server
  /// recognises instead of creating the record twice.
  ///
  /// A rejected record is rolled back by its pusher ([RejectionAware]); an
  /// outdated one (the server applied none of it) is marked outdated and its
  /// row shows the server's values again ([ServerShadow]). Both take the
  /// server row the answer carries (`current`) when there is one, over the
  /// values last known; an accepted answer carries none. An edit of another
  /// driver's customer ([foreignCustomerReason]) is marked awaiting approval
  /// and its row keeps the values sent. Once the queue is settled, the
  /// server values kept for rows with nothing pending are forgotten.
  Future<void> push() async {
    await _push();
    await _shadow.clearSettled();
  }

  Future<void> _push() async {
    final pending = await _queue.getPending();
    if (pending.isEmpty) return;
    final entityIdOf = {for (final c in pending) c.id: c.entityId};

    final plans = <EntityPusher, PushPlan>{};
    final body = <String, dynamic>{};
    for (final pusher in _pushers) {
      final changes = [
        for (final c in pending)
          if (c.entity == pusher.entity) c,
      ];
      if (changes.isEmpty) continue;
      final plan = await pusher.plan(changes);
      plans[pusher] = plan;
      if (plan.records.isNotEmpty) {
        body[pusher.wireKey] = [for (final r in plan.records) r.body];
      }
    }

    await _db.transaction(() async {
      for (final plan in plans.values) {
        for (final rejection in plan.rejections) {
          for (final id in rejection.changeIds) {
            await _queue.markRejected(id, rejection.reason);
          }
        }
        if (plan.settled.isNotEmpty) await _queue.markSent(plan.settled);
      }
      for (final MapEntry(key: pusher, value: plan) in plans.entries) {
        await _applyRejected(pusher, [
          for (final r in plan.rejections) ...r.changeIds,
        ], entityIdOf);
      }
    });
    if (body.isEmpty) return;

    final response = await _dio.post('/sync/push', data: body);
    final data = Map<String, dynamic>.from(response.data['data'] as Map);

    await _db.transaction(() async {
      for (final MapEntry(key: pusher, value: plan) in plans.entries) {
        final results = {
          for (final r in (data[pusher.wireKey] as List? ?? const []))
            (r as Map)['uuid']: Map<String, dynamic>.from(r),
        };
        // A change settles only after every record built from it did.
        final rejectedWith = <int, String>{};
        final currentOf = <String, Json>{};
        final unanswered = <int>{};
        final accepted = <int>{};
        final awaiting = <int>{};
        final outdated = <int>{};
        final outdatedRows = <String, List<int>>{};
        for (final record in plan.records) {
          final result = results[record.uuid];
          final status = result?['status'];
          if (status == 'accepted' || status == 'outdated') {
            // An accepted record that waits for review is still accepted;
            // one that adds to another driver's customer has no server id.
            // An outdated one changed nothing: the server holds newer values
            // for every field it carried.
            final serverId = result!['server_id'];
            if (serverId is int) await pusher.applyAccepted(record, serverId);
            if (status == 'accepted' &&
                _approvalEntities.contains(pusher.entity) &&
                _reviewReasonsOf(result).any(foreignCustomerReasons.contains)) {
              awaiting.addAll(record.changeIds);
            } else if (status == 'accepted') {
              accepted.addAll(record.changeIds);
            } else {
              outdated.addAll(record.changeIds);
              outdatedRows[record.localId] = record.changeIds;
              final current = _currentOf(result);
              if (current != null) {
                await _shadow.keepCurrent(
                  pusher.entity,
                  record.localId,
                  current,
                );
              }
            }
          } else if (status == 'rejected') {
            final reason =
                (result!['error'] as String?) ?? 'Rechazado por el servidor.';
            for (final id in record.changeIds) {
              rejectedWith.putIfAbsent(id, () => reason);
            }
            final current = _currentOf(result);
            if (current != null) currentOf[record.localId] = current;
          } else {
            // No answer for this record: it stays pending for the next cycle.
            unanswered.addAll(record.changeIds);
          }
        }
        for (final MapEntry(key: id, value: reason) in rejectedWith.entries) {
          await _queue.markRejected(id, reason);
        }
        await _applyRejected(
          pusher,
          rejectedWith.keys,
          entityIdOf,
          currentOf: currentOf,
        );
        bool settles(int id) =>
            !rejectedWith.containsKey(id) && !unanswered.contains(id);
        await _queue.markSent([
          for (final id in accepted)
            if (settles(id) && !awaiting.contains(id)) id,
        ]);
        await _queue.markAwaitingApproval([
          for (final id in awaiting)
            if (settles(id)) id,
        ]);
        // Outdated only when no record built from the change applied
        // anything.
        final dropped = {
          for (final id in outdated)
            if (settles(id) && !accepted.contains(id) && !awaiting.contains(id))
              id,
        };
        await _queue.markOutdated(dropped.toList());
        for (final MapEntry(key: localId, value: ids) in outdatedRows.entries) {
          if (ids.every(dropped.contains)) {
            await _shadow.restoreIfSettled(pusher.entity, localId);
          }
        }
      }
    });
  }

  /// Lets [pusher] take back what its rejected local records moved, once
  /// per local record, with the server row the answer carried for it
  /// ([currentOf], by local id).
  Future<void> _applyRejected(
    EntityPusher pusher,
    Iterable<int> changeIds,
    Map<int, String> entityIdOf, {
    Map<String, Json> currentOf = const {},
  }) async {
    if (pusher is! RejectionAware) return;
    final localIds = {for (final id in changeIds) ?entityIdOf[id]};
    for (final localId in localIds) {
      await (pusher as RejectionAware).applyRejected(
        localId,
        current: currentOf[localId],
      );
    }
  }

  /// The review reasons of an accepted answer; none when it omits them.
  static List<String> _reviewReasonsOf(Json result) =>
      switch (result['review_reasons']) {
        final List reasons => [for (final r in reasons) '$r'],
        _ => const [],
      };

  /// The server row an answer carries, in pull shape.
  static Json? _currentOf(Json result) => switch (result['current']) {
    final Map current => Map<String, dynamic>.from(current),
    _ => null,
  };

  Future<SyncStatus> status() => _statusQuery().getSingle();

  Stream<SyncStatus> watchStatus() => _statusQuery().watchSingle();

  /// Pending changes held by an open visit, with the stop of that visit:
  /// the same rule as `awaitsOpenVisit`, a pending stop of today's route
  /// with no visit recorded. A cancellation waits with its record.
  static const _heldSql =
      'WITH open_stops AS ('
      'SELECT s.route_stop_id AS id FROM route_stops s '
      'JOIN routes r ON r.route_id = s.route_id '
      "WHERE s.status = 'pending' AND r.route_date = ?6 AND NOT EXISTS "
      '(SELECT 1 FROM visits v WHERE v.route_stop_id = s.route_stop_id)), '
      'linked AS ('
      "SELECT 'sale' AS entity, sale_id AS id, visit_id FROM sales "
      "UNION ALL SELECT 'sale_cancellation', sale_id, visit_id FROM sales "
      "UNION ALL SELECT 'payment', payment_id, visit_id FROM payments "
      "UNION ALL SELECT 'payment_cancellation', payment_id, visit_id "
      'FROM payments '
      "UNION ALL SELECT 'container_movement', container_movement_id, "
      'visit_id FROM container_movements), '
      'held AS (SELECT l.visit_id AS stop_id FROM pending_changes c '
      'JOIN linked l ON l.entity = c.entity AND l.id = c.entity_id '
      'WHERE c.status = ?1 AND l.visit_id IN (SELECT id FROM open_stops)) ';

  Selectable<SyncStatus> _statusQuery() => _db
      .customSelect(
        '${_heldSql}SELECT '
        '(SELECT COUNT(*) FROM held) AS held, '
        '(SELECT group_concat(DISTINCT stop_id) FROM held) AS held_stops, '
        '(SELECT COUNT(*) FROM pending_changes WHERE status = ?1) AS pending, '
        '(SELECT COUNT(*) FROM pending_changes WHERE status = ?2) AS rejected, '
        '(SELECT value FROM sync_state WHERE key = ?3) AS at, '
        '(SELECT value FROM sync_state WHERE key = ?4) AS result, '
        '(SELECT value FROM sync_state WHERE key = ?5) AS error',
        variables: [
          Variable.withString(PendingStatus.pending.wireName),
          Variable.withString(PendingStatus.rejected.wireName),
          Variable.withString(lastCycleAtKey),
          Variable.withString(lastCycleResultKey),
          Variable.withString(lastCycleErrorKey),
          Variable.withString(dateOnly(_now())),
        ],
        readsFrom: {
          _db.pendingChangeTable,
          _db.syncStateTable,
          _db.routeTable,
          _db.routeStopTable,
          _db.visitTable,
          _db.saleTable,
          _db.paymentTable,
          _db.containerMovementTable,
        },
      )
      .map((row) {
        final at = row.readNullable<String>('at');
        final error = row.readNullable<String>('error');
        final heldStops = row.readNullable<String>('held_stops');
        return SyncStatus(
          pendingCount: row.read<int>('pending'),
          rejectedCount: row.read<int>('rejected'),
          heldCount: row.read<int>('held'),
          heldStopIds: heldStops == null
              ? const {}
              : heldStops.split(',').toSet(),
          lastCycleAt: at == null ? null : DateTime.parse(at).toLocal(),
          lastResult: SyncCycleResult.fromWire(
            row.readNullable<String>('result'),
          ),
          lastError: (error == null || error.isEmpty) ? null : error,
        );
      });

  Future<void> _recordCycle(SyncCycleResult result, String? error) =>
      _db.transaction(() async {
        Future<void> put(String key, String value) => _db
            .into(_db.syncStateTable)
            .insertOnConflictUpdate(
              SyncStateTableCompanion.insert(key: key, value: value),
            );
        await put(lastCycleAtKey, _now().toUtc().toIso8601String());
        await put(lastCycleResultKey, result.wireName);
        await put(lastCycleErrorKey, error ?? '');
      });

  /// Whether [error] means the server could not be reached at all, as
  /// opposed to a server that answered with an error.
  static bool _isOffline(Object error) => switch (error) {
    DioException(
      type: DioExceptionType.connectionError ||
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout,
    ) =>
      true,
    DioException(error: SocketException()) => true,
    _ => false,
  };

  static String _describe(Object error) => switch (error) {
    DioException(type: DioExceptionType.badResponse, :final response) =>
      'El servidor respondió ${response?.statusCode}.',
    DioException() => 'Sin conexión con el servidor.',
    _ => error.toString(),
  };

  Future<void> dispose() => _running.close();
}
