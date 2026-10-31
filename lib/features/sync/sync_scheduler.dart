import 'dart:async';

typedef PeriodicTimerFactory =
    Timer Function(Duration interval, void Function(Timer) onTick);

typedef DelayedTimerFactory =
    Timer Function(Duration delay, void Function() callback);

/// Decides when a sync cycle runs: on app open, on return to the
/// foreground, when connectivity comes back, on a timer while the app is in
/// the foreground, shortly after a new local change, and on demand.
///
/// Platform signals arrive as plain streams so this has no plugin
/// dependency; the engine's single-flight guard absorbs overlapping triggers.
class SyncScheduler {
  SyncScheduler({
    required Future<void> Function() runCycle,
    required Stream<bool> foreground,
    required Stream<bool> online,
    required Stream<int> pendingCount,
    this.interval = const Duration(minutes: 5),
    this.debounce = const Duration(seconds: 3),
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
  final Future<void> Function() _runCycle;
  final Stream<bool> _foregroundSignal;
  final Stream<bool> _onlineSignal;
  final Stream<int> _pendingCountSignal;
  final PeriodicTimerFactory _periodic;
  final DelayedTimerFactory _delayed;
  final _subscriptions = <StreamSubscription<Object>>[];
  Timer? _timer;
  Timer? _debounceTimer;
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
  Future<void> syncNow() => _runCycle();

  void _onForeground(bool isForeground) {
    _foreground = isForeground;
    if (isForeground) {
      _trigger();
      _startTimer();
    } else {
      _stopTimer();
      _cancelDebounce();
    }
  }

  void _onOnline(bool isOnline) {
    final wasOffline = _online == false;
    _online = isOnline;
    if (isOnline && wasOffline) _trigger();
    if (!isOnline) _cancelDebounce();
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

  void _trigger() => unawaited(_runCycle());

  void dispose() {
    _stopTimer();
    _cancelDebounce();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
  }
}
