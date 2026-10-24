import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

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
  late StreamController<bool> foreground;
  late StreamController<bool> online;
  late List<_ManualTimer> timers;
  late SyncScheduler scheduler;

  _ManualTimer? activeTimer() => timers.where((t) => !t.cancelled).firstOrNull;

  setUp(() {
    cycles = 0;
    foreground = StreamController<bool>(sync: true);
    online = StreamController<bool>(sync: true);
    timers = [];
    scheduler = SyncScheduler(
      runCycle: () async => cycles++,
      foreground: foreground.stream,
      online: online.stream,
      interval: const Duration(minutes: 5),
      periodic: (interval, onTick) {
        final timer = _ManualTimer(interval, onTick);
        timers.add(timer);
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
}
