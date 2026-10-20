import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';
import 'package:app/features/sync/presentation/widgets/sync_status_button.dart';

class SyncStatusButtonContainer extends ConsumerWidget {
  const SyncStatusButtonContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider).value ?? const SyncStatus();
    final isRunning = ref.watch(syncRunningProvider).value ?? false;

    return SyncStatusButton(
      status: status,
      isRunning: isRunning,
      onPressed: () => ref.read(syncEngineProvider).runCycle(),
    );
  }
}
