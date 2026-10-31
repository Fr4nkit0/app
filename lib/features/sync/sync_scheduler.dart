import 'dart:async';

import 'package:app/features/sync/domain/models/sync_status.dart';

typedef PeriodicTimerFactory =
    Timer Function(Duration interval, void Function(Timer) onTick);

typedef DelayedTimerFactory =
    Timer Function(Duration delay, void Function() callback);

/// Decides when a sync cycle runs: on app open, on return to the
/// foreground, when connectivity comes back, on a timer while the app is in
/// the foreground, shortly after a new local change, and on demand.
///
/// When a cycle cannot reach the server while the phone looks online, it
/// retries with a growing delay, so a server that comes back is noticed
/// without waiting for the timer or a connectivity change.
///
/// Platform signals arrive as plain streams so this has no plugin
/// dependency; the engine's single-flight guard absorbs overlapping triggers.
class SyncScheduler {
  SyncScheduler({
    required Future<SyncStatus> Function() runCycle,
    required Stream<bool> foreground,
    required Stream<bool> online,
    required Stream<int> pendingCount,
    this.interval = const Duration(minutes: 5),
    this.debounce = const Duration(seconds: 3),
    this.retryBackoff = const [
      Duration(seconds: 15),
      Duration(seconds: 30),
      Duration(seconds: 60),
      Duration(seconds: 120),
    ],
    PeriodicTimerFactory? periodic,
    DelayedTimerFactory? delayed,
  }) : _runCycle = runCycle,
       _foregroundSignal = foreground,
       _onlineSignal = online,
       _pendingCountSignal = pendingCount,
       _periodic = periodic ?? Timer.periodic,
       _delayed = delayed ?? Timer.new;

  final Duration interval;

  /// Quiet time after the last new local change before its cycle runs, so a
  /// burst of writes is sent in one cycle.
  final Duration debounce;

  /// Delays between retries while the server is unreachable; the last one
  /// repeats until the server answers.
  final List<Duration> retryBackoff;
  final Future<SyncStatus> Function() _runCycle;
  final Stream<bool> _foregroundSignal;
  final Stream<bool> _onlineSignal;
  final Stream<int> _pendingCountSignal;
  final PeriodicTimerFactory _periodic;
  final DelayedTimerFactory _delayed;
  final _subscriptions = <StreamSubscription<Object>>[];
  Timer? _timer;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  int _retryStep = 0;
  SyncStatus? _lastStatus;
  bool _disposed = false;
  bool? _online;
  bool _foreground = true;
  int? _pendingCount;

  /// Call once when the app opens.
  void start() {
    _subscriptions
      ..add(_foregroundSignal.listen(_onForeground))
      ..add(_onlineSignal.listen(_onOnline))
      ..add(_pendingCountSignal.listen(_onPendingCount));
    _trigger();
    _startTimer();
  }

  /// Manual trigger (sync button).
  Future<void> syncNow() => _cycle();

  void _onForeground(bool isForeground) {
    _foreground = isForeground;
    if (isForeground) {
      _trigger();
      _startTimer();
    } else {
      _stopTimer();
      _cancelDebounce();
      _cancelRetry();
    }
  }

  void _onOnline(bool isOnline) {
    final wasOffline = _online == false;
    _online = isOnline;
    if (isOnline && wasOffline) _trigger();
    if (!isOnline) {
      _cancelDebounce();
      _cancelRetry();
    }
  }

  /// Only an increase is a new local change. The count stays up while
  /// changes are held in the queue (an open visit's records), so reacting to
  /// anything else would run cycles over and over.
  void _onPendingCount(int count) {
    final previous = _pendingCount;
    _pendingCount = count;
    if (previous == null || count <= previous) return;
    if (!_foreground || _online == false) return;
    _cancelDebounce();
    _debounceTimer = _delayed(debounce, () {
      _debounceTimer = null;
      _trigger();
    });
  }

  void _startTimer() {
    _timer ??= _periodic(interval, (_) => _trigger());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryStep = 0;
  }

  void _trigger() => unawaited(_cycle());

  /// Every cycle this starts goes through here, so its result decides the
  /// retry.
  Future<void> _cycle() async {
    final status = await _runCycle();
    // Triggers that joined the engine's in-flight cycle get the same status:
    // react to it once.
    if (_disposed || identical(status, _lastStatus)) return;
    _lastStatus = status;
    if (status.lastResult == SyncCycleResult.offline) {
      _scheduleRetry();
    } else {
      // The server answered: nothing to retry.
      _cancelRetry();
    }
  }

  /// Replaces any pending retry, so there is never more than one.
  void _scheduleRetry() {
    if (!_foreground || _online == false) return;
    _retryTimer?.cancel();
    final delay = retryBackoff[_retryStep];
    if (_retryStep < retryBackoff.length - 1) _retryStep++;
    _retryTimer = _delayed(delay, () {
      _retryTimer = null;
      _trigger();
    });
  }

  void dispose() {
    _disposed = true;
    _stopTimer();
    _cancelDebounce();
    _cancelRetry();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
  }
}
