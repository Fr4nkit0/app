import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/background/background_sync_task.dart';
import 'package:app/features/sync/background/cycle_lease.dart';
import 'package:app/features/sync/background/leased_sync_engine.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';

import 'background_harness.dart';

void main() {
  late AppDatabase db;
  late FakeSyncServer server;
  late DateTime clock;
  DateTime now() => clock;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    server = FakeSyncServer();
    clock = DateTime(2026, 10, 31, 9);
  });
  tearDown(() => db.close());

  group('S2 the foreground lease is owned per instance', () {
    test('two launches of the app hold different lease owners', () {
      LeasedSyncEngine launch() {
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            apiBaseUrlProvider.overrideWithValue('https://unreachable.test'),
            leasedSyncEngineOverride(owner: foregroundLeaseOwner),
          ],
        );
        addTearDown(container.dispose);
        return container.read(syncEngineProvider) as LeasedSyncEngine;
      }

      final first = launch().leaseOwner;
      final second = launch().leaseOwner;

      expect(first, startsWith(foregroundLeaseOwner));
      expect(second, startsWith(foregroundLeaseOwner));
      expect(first, isNot(second));
    });

    test(
      'reopening the app during a slow push never sends a second push',
      () async {
        await createCustomer(db, 'c-1');
        server.holdPush = Completer<void>();
        final backedOut = buildEngine(db, server, owner: 'foreground#1');
        final reopened = buildEngine(
          db,
          server,
          owner: 'foreground#2',
          delayed: (d, cb) => ManualTimer(d, (_) => cb()),
        );

        final slow = backedOut.runCycle();
        await pumpEventQueue();
        await reopened.runCycle();
        server.holdPush!.complete();
        await slow;

        expect(server.calls.where((c) => c == '/sync/push').length, 1);
        expect(await DriftPendingChangeRepository(db).countPending(), 0);
      },
    );
  });

  group('S3 a lease left by a killed process', () {
    test('stops blocking within a minute', () async {
      await CycleLease(db, owner: 'background#killed', now: now).acquire();
      clock = clock.add(const Duration(seconds: 61));

      expect(
        await CycleLease(db, owner: 'foreground#1', now: now).acquire(),
        isTrue,
      );
    });

    test('while it is alive, its heartbeat keeps it held', () async {
      await createCustomer(db, 'c-1');
      server.holdPush = Completer<void>();
      final heartbeats = <ManualTimer>[];
      final holder = buildEngine(
        db,
        server,
        owner: 'background#1',
        now: now,
        periodic: (d, cb) {
          final t = ManualTimer(d, cb);
          heartbeats.add(t);
          return t;
        },
      );

      final cycle = holder.runExclusiveCycle();
      await pumpEventQueue();
      for (var i = 0; i < 4; i++) {
        clock = clock.add(const Duration(seconds: 20));
        heartbeats.single.fire();
        await pumpEventQueue();
      }

      expect(
        await CycleLease(db, owner: 'foreground#1', now: now).acquire(),
        isFalse,
        reason: '80 s after it started, a live cycle still holds the lease',
      );
      server.holdPush!.complete();
      await cycle;
      expect(heartbeats.single.isActive, isFalse);
    });

    test(
      'the waiting foreground shows a running sync and retries once the lease expires',
      () async {
        await createCustomer(db, 'c-1');
        await CycleLease(db, owner: 'background#killed', now: now).acquire();
        final retries = <ManualTimer>[];
        final foreground = buildEngine(
          db,
          server,
          owner: 'foreground#1',
          now: now,
          delayed: (d, cb) {
            final t = ManualTimer(d, (_) => cb());
            retries.add(t);
            return t;
          },
        );
        final running = <bool>[];
        final sub = foreground.watchRunning().listen(running.add);
        addTearDown(sub.cancel);

        final skipped = await foreground.runCycle();
        await pumpEventQueue();

        expect(server.calls, isEmpty);
        expect(
          skipped.lastResult,
          isNull,
          reason: 'no offline result recorded',
        );
        expect(
          running.last,
          isTrue,
          reason: 'waiting on the lease reads as syncing',
        );
        expect(retries.single.duration, const Duration(seconds: 60));

        clock = clock.add(const Duration(seconds: 60));
        retries.single.fire();
        await pumpEventQueue();
        await foreground.runCycle();

        expect(server.calls.first, '/sync/push');
        expect(await DriftPendingChangeRepository(db).countPending(), 0);
        expect(running.last, isFalse);
      },
    );
  });
}
