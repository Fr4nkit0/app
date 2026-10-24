import 'dart:async';

typedef PeriodicTimerFactory =
    Timer Function(Duration interval, void Function(Timer) onTick);

/// Decides when a sync cycle runs: on app open, on return to the
/// foreground, when connectivity comes back, on a timer while the app is in
/// the foreground, and on demand.
///
/// Platform signals arrive as plain streams so this has no plugin
/// dependency; the engine's single-flight guard absorbs overlapping triggers.
class SyncScheduler {
  SyncScheduler({
    required Future<void> Function() runCycle,
    required Stream<bool> foreground,
    required Stream<bool> online,
    this.interval = const Duration(minutes: 5),
    PeriodicTimerFactory? periodic,
  }) : _runCycle = runCycle,
       _foregroundSignal = foreground,
       _onlineSignal = online,
       _periodic = periodic ?? Timer.periodic;

  final Duration interval;
  final Future<void> Function() _runCycle;
  final Stream<bool> _foregroundSignal;
  final Stream<bool> _onlineSignal;
  final PeriodicTimerFactory _periodic;
  final _subscriptions = <StreamSubscription<bool>>[];
  Timer? _timer;
  bool? _online;

  /// Call once when the app opens.
  void start() {
    _subscriptions
      ..add(_foregroundSignal.listen(_onForeground))
      ..add(_onlineSignal.listen(_onOnline));
    _trigger();
    _startTimer();
  }

  /// Manual trigger (sync button).
  Future<void> syncNow() => _runCycle();

  void _onForeground(bool isForeground) {
    if (isForeground) {
      _trigger();
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _onOnline(bool isOnline) {
    final wasOffline = _online == false;
    _online = isOnline;
    if (isOnline && wasOffline) _trigger();
  }

  void _startTimer() {
    _timer ??= _periodic(interval, (_) => _trigger());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _trigger() => unawaited(_runCycle());

  void dispose() {
    _stopTimer();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
  }
}
