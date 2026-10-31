import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/sync_scheduler.dart';

/// Periodic timer the test fires by hand.
class _ManualTimer implements Timer {
  _ManualTimer(this.interval, this.onTick);

  final Duration interval;
  final void Function(Timer) onTick;
  bool cancelled = false;
  int ticks = 0;

  void fire() {
    ticks++;
    onTick(this);
  }

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => ticks;
}

void main() {
  late int cycles;
  late SyncCycleResult result;
  late StreamController<bool> foreground;
  late StreamController<bool> online;
  late StreamController<int> pendingCount;
  late List<_ManualTimer> timers;
  late List<_ManualTimer> debounces;
  late List<_ManualTimer> retries;
  late SyncScheduler scheduler;

  _ManualTimer? activeTimer() => timers.where((t) => !t.cancelled).firstOrNull;
  _ManualTimer? activeDebounce() =>
      debounces.where((t) => !t.cancelled && t.ticks == 0).firstOrNull;
  Iterable<_ManualTimer> pendingRetries() =>
      retries.where((t) => !t.cancelled && t.ticks == 0);
  _ManualTimer? activeRetry() => pendingRetries().firstOrNull;

  setUp(() {
    cycles = 0;
    result = SyncCycleResult.success;
    foreground = StreamController<bool>(sync: true);
    online = StreamController<bool>(sync: true);
    pendingCount = StreamController<int>(sync: true);
    timers = [];
    debounces = [];
    retries = [];
    scheduler = SyncScheduler(
      runCycle: () async {
        cycles++;
        return SyncStatus(lastResult: result);
      },
      foreground: foreground.stream,
      online: online.stream,
      pendingCount: pendingCount.stream,
      interval: const Duration(minutes: 5),
      debounce: const Duration(seconds: 3),
      periodic: (interval, onTick) {
        final timer = _ManualTimer(interval, onTick);
        timers.add(timer);
        return timer;
      },
      delayed: (duration, callback) {
        final timer = _ManualTimer(duration, (_) => callback());
        // The debounce and the retry both come from here; tell them apart by
        // the requested delay.
        (duration == const Duration(seconds: 3) ? debounces : retries).add(
          timer,
        );
        return timer;
      },
    );
  });
  tearDown(() => scheduler.dispose());

  test('opening the app runs a cycle', () {
    scheduler.start();

    expect(cycles, 1);
  });

  test('returning to the foreground runs a cycle', () {
    scheduler.start();
    foreground.add(false);
    foreground.add(true);

    expect(cycles, 2);
  });

  test('regaining connectivity runs a cycle; staying online does not', () {
    scheduler.start();
    online.add(true);
    online.add(false);
    online.add(true);
    online.add(true);

    expect(cycles, 2);
  });

  test('the timer runs cycles only while the app is in the foreground', () {
    scheduler.start();
    expect(activeTimer()!.interval, const Duration(minutes: 5));
    activeTimer()!.fire();
    expect(cycles, 2);

    foreground.add(false);
    expect(activeTimer(), isNull);

    foreground.add(true);
    activeTimer()!.fire();
    expect(cycles, 4);
  });

  test('the manual button runs a cycle', () async {
    await scheduler.syncNow();

    expect(cycles, 1);
  });

  group('a new local change', () {
    // start() runs the app-open cycle; these tests count cycles after it.
    void startOnline({int pending = 0}) {
      scheduler.start();
      online.add(true);
      pendingCount.add(pending);
      cycles = 0;
    }

    test('while online runs exactly one cycle after the debounce', () {
      startOnline();
      pendingCount.add(1);

      expect(cycles, 0);
      expect(activeDebounce()!.interval, const Duration(seconds: 3));
      activeDebounce()!.fire();

      expect(cycles, 1);
      expect(activeDebounce(), isNull);
    });

    test('a burst of changes runs a single cycle', () {
      startOnline();
      pendingCount
        ..add(1)
        ..add(2)
        ..add(3);

      expect(debounces.where((t) => !t.cancelled), hasLength(1));
      activeDebounce()!.fire();

      expect(cycles, 1);
    });

    test('offline runs nothing; coming back online runs the usual cycle', () {
      startOnline();
      online.add(false);
      pendingCount.add(1);

      expect(activeDebounce(), isNull);
      expect(cycles, 0);

      online.add(true);
      expect(cycles, 1);
    });

    test('going offline during the debounce cancels it', () {
      startOnline();
      pendingCount.add(1);
      final pending = activeDebounce()!;
      online.add(false);

      expect(pending.cancelled, isTrue);
      expect(cycles, 0);
    });

    test('in the background runs nothing', () {
      startOnline();
      foreground.add(false);
      pendingCount.add(1);

      expect(activeDebounce(), isNull);
      expect(cycles, 0);
    });

    test('going to the background during the debounce cancels it', () {
      startOnline();
      pendingCount.add(1);
      final pending = activeDebounce()!;
      foreground.add(false);

      expect(pending.cancelled, isTrue);
      expect(cycles, 0);
    });

    test('changes held in the queue do not run repeated cycles', () {
      startOnline(pending: 2);
      // The queue re-emits the same count (held records of an open visit)
      // and drops when other changes are sent: neither is a new change.
      pendingCount
        ..add(2)
        ..add(2)
        ..add(1);

      expect(activeDebounce(), isNull);
      expect(cycles, 0);
    });

    test(
      'the count already pending when the app opens is not a new change',
      () {
        scheduler.start();
        pendingCount.add(4);

        expect(activeDebounce(), isNull);
        expect(cycles, 1);
      },
    );

    test('dispose cancels a scheduled cycle', () {
      startOnline();
      pendingCount.add(1);
      final pending = activeDebounce()!;
      scheduler.dispose();

      expect(pending.cancelled, isTrue);
    });
  });

  group('an unreachable server', () {
    // The retry is scheduled once the cycle's status arrives.
    Future<void> startUnreachable() async {
      result = SyncCycleResult.offline;
      scheduler.start();
      online.add(true);
      await pumpEventQueue();
    }

    test('while online retries after 15 seconds', () async {
      await startUnreachable();

      expect(cycles, 1);
      expect(activeRetry()!.interval, const Duration(seconds: 15));
      activeRetry()!.fire();

      expect(cycles, 2);
    });

    test('backs off 15, 30, 60, 120 and then stays at 120 seconds', () async {
      await startUnreachable();

      final delays = <Duration>[];
      for (var i = 0; i < 6; i++) {
        expect(pendingRetries(), hasLength(1));
        final retry = activeRetry()!;
        delays.add(retry.interval);
        retry.fire();
        await pumpEventQueue();
      }

      expect(delays, const [
        Duration(seconds: 15),
        Duration(seconds: 30),
        Duration(seconds: 60),
        Duration(seconds: 120),
        Duration(seconds: 120),
        Duration(seconds: 120),
      ]);
    });

    test('a successful retry stops retrying and resets the backoff', () async {
      await startUnreachable();
      activeRetry()!.fire();
      await pumpEventQueue();
      result = SyncCycleResult.success;
      activeRetry()!.fire();
      await pumpEventQueue();

      expect(activeRetry(), isNull);

      result = SyncCycleResult.offline;
      await scheduler.syncNow();
      await pumpEventQueue();

      expect(activeRetry()!.interval, const Duration(seconds: 15));
    });

    test('a failure (the server answered) schedules no retry', () async {
      result = SyncCycleResult.failure;
      scheduler.start();
      online.add(true);
      await pumpEventQueue();

      expect(retries, isEmpty);
    });

    test('no retry while connectivity is offline', () async {
      scheduler.start();
      online.add(false);
      await pumpEventQueue();
      result = SyncCycleResult.offline;
      await scheduler.syncNow();
      await pumpEventQueue();

      expect(retries, isEmpty);
    });

    test('going offline cancels a pending retry', () async {
      await startUnreachable();
      final retry = activeRetry()!;
      online.add(false);

      expect(retry.cancelled, isTrue);
    });

    test('going to the background cancels a pending retry', () async {
      await startUnreachable();
      final retry = activeRetry()!;
      foreground.add(false);
      await pumpEventQueue();

      expect(retry.cancelled, isTrue);
      expect(activeRetry(), isNull);
    });

    test('dispose cancels a pending retry', () async {
      await startUnreachable();
      final retry = activeRetry()!;
      scheduler.dispose();

      expect(retry.cancelled, isTrue);
    });

    test('a manual sync during a pending retry keeps a single retry', () async {
      await startUnreachable();
      await scheduler.syncNow();
      await pumpEventQueue();

      expect(pendingRetries(), hasLength(1));
    });
  });
}
