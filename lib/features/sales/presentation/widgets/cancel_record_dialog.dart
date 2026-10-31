import 'package:flutter/material.dart';

import 'package:app/core/presentation/failure_message.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/widgets/top_toast.dart';
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

/// Asks before cancelling a sale, whose payments are cancelled with it.
Future<CancelConfirmation?> confirmCancelSale(BuildContext context) =>
    confirmCancelRecord(
      context,
      title: '¿Anular la venta?',
      message:
          'También se anulan los cobros de esta venta: la deuda vuelve a '
          'como estaba antes y los productos vuelven al camión.',
    );

/// Asks before cancelling a payment that did not settle a sale.
Future<CancelConfirmation?> confirmCancelPayment(BuildContext context) =>
    confirmCancelRecord(
      context,
      title: '¿Anular el cobro?',
      message: 'El monto vuelve a sumarse a la deuda del cliente.',
    );

/// Runs a confirmed [cancel] and tells the driver how it went: [done] when
/// it worked, the failure otherwise.
Future<void> runCancellation(
  BuildContext context,
  Future<void> Function() cancel, {
  required String done,
}) async {
  try {
    await cancel();
  } catch (error) {
    if (!context.mounted) return;
    TopToast.show(
      context,
      message: failureMessage(error, fallback: 'No se anuló. Reintentá.'),
      icon: Icons.error_outline,
      color: MarilinColors.destructive,
    );
    return;
  }
  if (!context.mounted) return;
  TopToast.show(
    context,
    message: done,
    icon: Icons.check_circle_rounded,
    color: MarilinColors.success,
  );
}

/// The button that starts the cancellation of a sale or payment, shown
/// below the record.
class CancelRecordAction extends StatelessWidget {
  const CancelRecordAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: TextButton.styleFrom(foregroundColor: MarilinColors.destructive),
    icon: const Icon(Icons.block, size: 18),
    label: Text(label),
    onPressed: onPressed,
  );
}

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
