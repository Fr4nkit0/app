import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// Shows whether one record still has to reach the server.
///
/// Nothing for a record with no queue row or one already sent; "Sin enviar"
/// while pending; "Rechazado" (tappable, shows the server reason) when refused.
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.change});

  final PendingChange? change;

  @override
  Widget build(BuildContext context) {
    final current = change;
    if (current == null) return const SizedBox.shrink();
    return switch (current.status) {
      PendingStatus.sent => const SizedBox.shrink(),
      PendingStatus.pending => const SyncStatusPill(
        status: PendingStatus.pending,
      ),
      PendingStatus.rejected => _RejectedBadge(reason: current.rejectionReason),
    };
  }
}

/// The non-interactive pill for [status]; empty when the status is sent.
class SyncStatusPill extends StatelessWidget {
  const SyncStatusPill({super.key, required this.status});

  final PendingStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;
    final (label, icon, color) = switch (status) {
      PendingStatus.pending => (
        'Sin enviar',
        Icons.cloud_upload_outlined,
        tokens.brandBlue,
      ),
      PendingStatus.rejected => (
        'Rechazado',
        Icons.error_outline_rounded,
        tokens.destructive,
      ),
      PendingStatus.sent => (null, null, null),
    };
    if (label == null || icon == null || color == null) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label: label,
      button: status == PendingStatus.rejected,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectedBadge extends StatelessWidget {
  const _RejectedBadge({required this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showReason(context),
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: const Center(
          widthFactor: 1,
          child: SyncStatusPill(status: PendingStatus.rejected),
        ),
      ),
    );
  }

  Future<void> _showReason(BuildContext context) {
    final text = reason?.trim() ?? '';
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('El servidor rechazó este cambio'),
        content: Text(text.isEmpty ? 'Sin motivo informado.' : text),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
