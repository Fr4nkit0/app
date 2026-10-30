import 'package:flutter/material.dart';

import 'package:app/features/sales/domain/cancellation_reason.dart';

/// The driver confirmed the cancellation; [reason] is null when left blank.
typedef CancelConfirmation = ({String? reason});

/// Asks before cancelling a sale or a payment, with an optional reason.
/// Returns null when the driver backs out.
Future<CancelConfirmation?> confirmCancelRecord(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<CancelConfirmation>(
  context: context,
  builder: (_) => _CancelRecordDialog(title: title, message: message),
);

class _CancelRecordDialog extends StatefulWidget {
  const _CancelRecordDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<_CancelRecordDialog> createState() => _CancelRecordDialogState();
}

class _CancelRecordDialogState extends State<_CancelRecordDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reason.text.trim();
    Navigator.of(
      context,
    ).pop<CancelConfirmation>((reason: reason.isEmpty ? null : reason));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _reason,
            maxLength: cancellationReasonMaxLength,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: _confirm,
          child: const Text('Anular'),
        ),
      ],
    );
  }
}
