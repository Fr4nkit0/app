import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/history/presentation/providers/history_repository_provider.dart';

class HistorySyncState {
  final double progress;
  final bool isSyncing;
  final int pendingCount;
  final bool isCompleted;

  const HistorySyncState({
    required this.progress,
    required this.isSyncing,
    required this.pendingCount,
    required this.isCompleted,
  });

  HistorySyncState copyWith({
    double? progress,
    bool? isSyncing,
    int? pendingCount,
    bool? isCompleted,
  }) {
    return HistorySyncState(
      progress: progress ?? this.progress,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class HistorySyncNotifier extends Notifier<HistorySyncState> {
  Timer? _timer;

  @override
  HistorySyncState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    // Start sync simulation automatically after state is built
    Future.microtask(() => startSync());

    return const HistorySyncState(
      progress: 0.0,
      isSyncing: false,
      pendingCount: 2,
      isCompleted: false,
    );
  }

  void startSync() {
    if (state.isSyncing) return;

    state = state.copyWith(
      isSyncing: true,
      progress: 0.0,
      pendingCount: 2,
      isCompleted: false,
    );

    const ticks = 30; // 3 seconds total at 100ms ticks
    int currentTick = 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      currentTick++;
      final currentProgress = currentTick / ticks;

      if (currentProgress >= 1.0) {
        timer.cancel();
        // Update database / mock repository to mark everything as synced
        await ref.read(historyRepositoryProvider).syncAllPending();
        state = state.copyWith(
          progress: 1.0,
          isSyncing: false,
          pendingCount: 0,
          isCompleted: true,
        );
      } else {
        // Smoothly reduce pending count as progress updates
        final remainingPending = currentProgress > 0.5 ? 1 : 2;
        state = state.copyWith(
          progress: currentProgress,
          pendingCount: remainingPending,
        );
      }
    });
  }
}

final historySyncProvider =
    NotifierProvider<HistorySyncNotifier, HistorySyncState>(() {
      return HistorySyncNotifier();
    });
