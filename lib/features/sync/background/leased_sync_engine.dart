import 'dart:async';

import '../domain/models/sync_status.dart';
import '../sync_engine.dart';
import '../sync_scheduler.dart';
import 'cycle_lease.dart';

/// [SyncEngine] whose cycle also holds a [CycleLease], so a cycle in the
/// foreground app and one in another isolate never overlap.
///
/// Within one isolate the base engine's single-flight guard still applies: a
/// trigger that fires while a cycle runs joins it.
class LeasedSyncEngine extends SyncEngine {
  LeasedSyncEngine({
    required super.dio,
    required super.db,
    required super.sync,
    required CycleLease lease,
    super.pushers,
    super.now,
    DelayedTimerFactory? delayed,
    PeriodicTimerFactory? periodic,
  }) : _lease = lease,
       _delayed = delayed ?? Timer.new,
       _periodic = periodic ?? Timer.periodic {
    _baseRunning = super.watchRunning().listen((_) => _emitActivity());
  }

  final CycleLease _lease;
  final DelayedTimerFactory _delayed;
  final PeriodicTimerFactory _periodic;
  final _activity = StreamController<bool>.broadcast();
  late final StreamSubscription<bool> _baseRunning;

  /// Callers of this isolate currently holding the lease.
  int _holders = 0;
  Timer? _heartbeat;

  /// Set while another isolate holds the lease and a retry is scheduled.
  Timer? _retry;

  String get leaseOwner => _lease.owner;

  bool get _waiting => _retry != null;

  /// Runs one cycle, or joins the one running in this isolate. Returns null
  /// without touching anything when another isolate holds the lease.
  Future<SyncStatus?> runExclusiveCycle() async {
    if (isRunning) return super.runCycle();
    _holders++;
    try {
      if (!await _lease.acquire()) return null;
      _cancelRetry();
      // Renewed well before it expires, so a live cycle never loses it.
      _heartbeat ??= _periodic(
        _lease.ttl ~/ 3,
        (_) => unawaited(_lease.renew()),
      );
      return await super.runCycle();
    } finally {
      // Triggers of this isolate share the lease; the last one out frees it.
      if (--_holders == 0) {
        _heartbeat?.cancel();
        _heartbeat = null;
        await _lease.release();
      }
    }
  }

  /// Same contract as [SyncEngine.runCycle]: never throws. When another
  /// isolate is mid-cycle it skips, reports the current status and retries
  /// once that lease expires; a live holder renews it, so the retry finds it
  /// busy and waits again, while a killed holder's lease runs out.
  @override
  Future<SyncStatus> runCycle() async {
    try {
      final ran = await runExclusiveCycle();
      if (ran != null) return ran;
      await _scheduleRetry();
      return await status();
    } catch (_) {
      return status();
    }
  }

  /// Running while a cycle runs here or this isolate waits on the lease, so
  /// the driver sees a sync in progress instead of the last offline result.
  @override
  Stream<bool> watchRunning() async* {
    yield isRunning || _waiting;
    yield* _activity.stream;
  }

  Future<void> _scheduleRetry() async {
    if (_waiting) return;
    final left = await _lease.remaining() ?? Duration.zero;
    if (_waiting) return;
    _retry = _delayed(left < _minRetry ? _minRetry : left, () {
      _retry = null;
      unawaited(runCycle());
    });
    _emitActivity();
  }

  static const _minRetry = Duration(seconds: 1);

  void _cancelRetry() {
    if (_retry == null) return;
    _retry!.cancel();
    _retry = null;
    _emitActivity();
  }

  void _emitActivity() {
    if (!_activity.isClosed) _activity.add(isRunning || _waiting);
  }

  @override
  Future<void> dispose() async {
    _retry?.cancel();
    _retry = null;
    _heartbeat?.cancel();
    await _baseRunning.cancel();
    await _activity.close();
    await super.dispose();
  }
}
