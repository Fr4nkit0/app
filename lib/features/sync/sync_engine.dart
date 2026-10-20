import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../core/services/database.helper.dart';
import 'data/repositories/pending_change.repository.dart';
import 'domain/models/pending_change.dart';
import 'domain/models/sync_status.dart';
import 'push/container_movement_pusher.dart';
import 'push/customer_pusher.dart';
import 'push/entity_pusher.dart';
import 'push/payment_pusher.dart';
import 'push/route_stop_pusher.dart';
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
       _pushers = pushers ?? defaultPushers(db),
       _now = now ?? DateTime.now;

  static const lastCycleAtKey = 'last_cycle_at';
  static const lastCycleResultKey = 'last_cycle_result';
  static const lastCycleErrorKey = 'last_cycle_error';

  /// Entity pushers in the server's dependency order.
  static List<EntityPusher> defaultPushers(AppDatabase db) => [
    CustomerPusher(db),
    RouteStopPusher(db),
    VisitPusher(db),
    ContainerMovementPusher(db),
    SalePusher(db),
    PaymentPusher(db),
  ];

  final Dio _dio;
  final AppDatabase _db;
  final SyncService _sync;
  final PendingChangeRepository _queue;
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
      await _recordCycle(SyncCycleResult.failure, _describe(e));
    }
    return status();
  }

  /// Sends every pending change in one request. Queue entries change state
  /// only after the server answered: a cut before the answer leaves them
  /// pending, and the retry carries the same client uuids, which the server
  /// recognises instead of creating the record twice.
  Future<void> push() async {
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
        final unanswered = <int>{};
        final accepted = <int>{};
        for (final record in plan.records) {
          final result = results[record.uuid];
          if (result?['status'] == 'accepted') {
            // An accepted record that waits for review is still accepted.
            await pusher.applyAccepted(record, result!['server_id'] as int);
            accepted.addAll(record.changeIds);
          } else if (result?['status'] == 'rejected') {
            final reason =
                (result!['error'] as String?) ?? 'Rejected by the server.';
            for (final id in record.changeIds) {
              rejectedWith.putIfAbsent(id, () => reason);
            }
          } else {
            // No answer for this record: it stays pending for the next cycle.
            unanswered.addAll(record.changeIds);
          }
        }
        for (final MapEntry(key: id, value: reason) in rejectedWith.entries) {
          await _queue.markRejected(id, reason);
        }
        await _applyRejected(pusher, rejectedWith.keys, entityIdOf);
        final sent = [
          for (final id in accepted)
            if (!rejectedWith.containsKey(id) && !unanswered.contains(id)) id,
        ];
        if (sent.isNotEmpty) await _queue.markSent(sent);
      }
    });
  }

  /// Lets [pusher] take back what its rejected local records moved, once
  /// per local record.
  Future<void> _applyRejected(
    EntityPusher pusher,
    Iterable<int> changeIds,
    Map<int, String> entityIdOf,
  ) async {
    if (pusher is! RejectionAware) return;
    final localIds = {for (final id in changeIds) ?entityIdOf[id]};
    for (final localId in localIds) {
      await (pusher as RejectionAware).applyRejected(localId);
    }
  }

  Future<SyncStatus> status() => _statusQuery().getSingle();

  Stream<SyncStatus> watchStatus() => _statusQuery().watchSingle();

  Selectable<SyncStatus> _statusQuery() => _db
      .customSelect(
        'SELECT '
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
        ],
        readsFrom: {_db.pendingChangeTable, _db.syncStateTable},
      )
      .map((row) {
        final at = row.readNullable<String>('at');
        final error = row.readNullable<String>('error');
        return SyncStatus(
          pendingCount: row.read<int>('pending'),
          rejectedCount: row.read<int>('rejected'),
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

  static String _describe(Object error) => switch (error) {
    DioException(type: DioExceptionType.badResponse, :final response) =>
      'Server answered ${response?.statusCode}.',
    DioException() => 'No connection to the server.',
    _ => error.toString(),
  };

  Future<void> dispose() => _running.close();
}
