import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/sync/presentation/providers/pending_change_repository_provider.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';
import 'package:app/features/sync/sync_scheduler.dart';

/// Wires platform signals (app lifecycle, connectivity) into the
/// [SyncScheduler] for as long as the signed-in shell is mounted.
class SyncTriggersHost extends ConsumerStatefulWidget {
  const SyncTriggersHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncTriggersHost> createState() => _SyncTriggersHostState();
}

class _SyncTriggersHostState extends ConsumerState<SyncTriggersHost> {
  final _foreground = StreamController<bool>.broadcast();
  late final AppLifecycleListener _lifecycle;
  late final SyncScheduler _scheduler;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => _foreground.add(true),
      onHide: () => _foreground.add(false),
    );
    final engine = ref.read(syncEngineProvider);
    _scheduler = SyncScheduler(
      runCycle: engine.runCycle,
      foreground: _foreground.stream,
      online: Connectivity().onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      ),
      pendingCount: ref
          .read(pendingChangeRepositoryProvider)
          .watchPendingCount(),
    )..start();
  }

  @override
  void dispose() {
    _scheduler.dispose();
    _lifecycle.dispose();
    _foreground.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
