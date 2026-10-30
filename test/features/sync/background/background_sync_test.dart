import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/background/background_sync.dart';
import 'package:app/features/sync/background/cycle_lease.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/sync_service.dart';

import 'background_harness.dart';

void main() {
  late AppDatabase db;
  late FakeSyncServer server;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    server = FakeSyncServer();
  });
  tearDown(() => db.close());

  Future<bool> online() async => true;

  test(
    'the background job runs the same engine cycle: push, then download',
    () async {
      await createCustomer(db, 'c-1');
      final engine = buildEngine(db, server);

      final outcome = await runBackgroundSync(engine: engine, isOnline: online);

      expect(outcome, BackgroundSyncOutcome.synced);
      expect(server.calls, ['/sync/push', '/sync/bootstrap']);
      expect(await DriftPendingChangeRepository(db).countPending(), 0);
    },
  );

  test(
    'while another isolate runs a cycle, the background job does not start a second one',
    () async {
      await createCustomer(db, 'c-1');
      final otherIsolate = CycleLease(db, owner: 'foreground');
      expect(await otherIsolate.acquire(), isTrue);

      final outcome = await runBackgroundSync(
        engine: buildEngine(db, server),
        isOnline: online,
      );

      expect(outcome, BackgroundSyncOutcome.busy);
      expect(server.calls, isEmpty);
      expect(await DriftPendingChangeRepository(db).countPending(), 1);
    },
  );

  test(
    'while the background job runs a cycle, the foreground app does not start a second one',
    () async {
      await createCustomer(db, 'c-1');
      expect(await CycleLease(db, owner: 'background').acquire(), isTrue);
      final foreground = buildEngine(db, server, owner: 'foreground');

      final status = await foreground.runCycle();

      expect(server.calls, isEmpty);
      expect(status.pendingCount, 1);
    },
  );

  test('once the background cycle ends, the next one can run', () async {
    final engine = buildEngine(db, server);
    await runBackgroundSync(engine: engine, isOnline: online);
    server.calls.clear();

    final foreground = buildEngine(db, server, owner: 'foreground');
    await foreground.runCycle();

    expect(server.calls, ['/sync/pull']);
  });

  test(
    'a lease left by a job the system killed expires and stops blocking',
    () async {
      final killedAt = DateTime(2026, 10, 19, 8);
      await CycleLease(db, owner: 'killed', now: () => killedAt).acquire();
      final later = CycleLease(
        db,
        owner: 'background',
        now: () => killedAt.add(const Duration(minutes: 11)),
      );

      expect(await later.acquire(), isTrue);
    },
  );

  test(
    'without network the job finishes without error and leaves everything for the next window',
    () async {
      await createCustomer(db, 'c-1');

      final outcome = await runBackgroundSync(
        engine: buildEngine(db, server),
        isOnline: () async => false,
      );

      expect(outcome, BackgroundSyncOutcome.offline);
      expect(server.calls, isEmpty);
      expect(await DriftPendingChangeRepository(db).countPending(), 1);
      expect(backgroundTaskResult(outcome), isTrue);
    },
  );

  test(
    'when the network check says online but the server is unreachable, the job still finishes without error',
    () async {
      await createCustomer(db, 'c-1');
      server.offline = true;

      final outcome = await runBackgroundSync(
        engine: buildEngine(db, server),
        isOnline: online,
      );

      expect(outcome, BackgroundSyncOutcome.failed);
      expect(backgroundTaskResult(outcome), isTrue);
      expect(await DriftPendingChangeRepository(db).countPending(), 1);
    },
  );

  test('a failing network check counts as offline instead of crashing', () async {
    final outcome = await runBackgroundSync(
      engine: buildEngine(db, server),
      isOnline: () async => throw StateError('plugin unavailable'),
    );

    expect(outcome, BackgroundSyncOutcome.offline);
    expect(server.calls, isEmpty);
  });

  test(
    'with nobody signed in the job does nothing and records no failure',
    () async {
      final outcome = await runBackgroundSync(
        engine: buildEngine(db, server),
        isOnline: online,
        isSignedIn: () async => false,
      );

      expect(outcome, BackgroundSyncOutcome.signedOut);
      expect(server.calls, isEmpty);
      expect((await engineStatus(db)).lastResult, isNull);
      expect(backgroundTaskResult(outcome), isTrue);
    },
  );

  group('a background failure does not touch pending changes or cursor', () {
    Future<String?> cursor() async => (await (db.select(db.syncStateTable)
          ..where((t) => t.key.equals(SyncService.pullCursorKey)))
        .getSingleOrNull())
        ?.value;

    setUp(() async {
      // The day is already downloaded: the stored cursor is the bootstrap's.
      await runBackgroundSync(engine: buildEngine(db, server), isOnline: online);
      server.calls.clear();
    });

    test('when the push fails', () async {
      final before = await cursor();
      await createCustomer(db, 'c-1');
      server.failWith['/sync/push'] = 500;

      final outcome = await runBackgroundSync(
        engine: buildEngine(db, server),
        isOnline: online,
      );

      expect(outcome, BackgroundSyncOutcome.failed);
      final queue = DriftPendingChangeRepository(db);
      expect(await queue.countPending(), 1);
      expect((await engineStatus(db)).rejectedCount, 0);
      expect(await cursor(), before);
      expect(server.calls, ['/sync/push']);
    });

    test('when the pull fails', () async {
      final before = await cursor();
      server.failWith['/sync/pull'] = 503;

      final outcome = await runBackgroundSync(
        engine: buildEngine(db, server),
        isOnline: online,
      );

      expect(outcome, BackgroundSyncOutcome.failed);
      expect(await cursor(), before);
      expect(before, '2026-10-19T12:00:00+00:00');
    });

    test('and the lease is freed for the next window', () async {
      server.failWith['/sync/pull'] = 503;
      await runBackgroundSync(engine: buildEngine(db, server), isOnline: online);

      expect(await CycleLease(db, owner: 'foreground').acquire(), isTrue);
    });
  });

  test(
    'triggers of the same isolate that overlap join one cycle and free the lease at the end',
    () async {
      await createCustomer(db, 'c-1');
      final engine = buildEngine(db, server, owner: 'foreground');

      await Future.wait([engine.runCycle(), engine.runCycle()]);

      expect(server.calls.where((c) => c == '/sync/push').length, 1);
      expect(
        await CycleLease(db, owner: 'background').acquire(),
        isTrue,
        reason: 'the lease must be free once the joined cycle ended',
      );
    },
  );
}
