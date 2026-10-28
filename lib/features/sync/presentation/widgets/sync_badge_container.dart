import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/providers/pending_change_repository_provider.dart';
import 'package:app/features/sync/presentation/widgets/sync_badge.dart';

/// Watches the latest queue row of one record and renders its [SyncBadge].
class SyncBadgeContainer extends ConsumerWidget {
  const SyncBadgeContainer({
    super.key,
    required this.entity,
    required this.entityId,
  });

  final PendingEntity entity;
  final String entityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final change = ref.watch(
      recordSyncStatusProvider((entity: entity, id: entityId)),
    );
    return SyncBadge(change: change.value);
  }
}
