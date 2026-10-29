import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';

/// The catalog carries no icon: types alternate the jug and bottle icons in
/// catalog order.
IconData containerTypeIcon(int position) =>
    position.isEven ? Icons.water_drop_outlined : Icons.local_drink_outlined;

/// Asks how many containers of each type the customer hands back; each type
/// goes from 0 up to the customer's [custody] of it.
class ContainerReturnDialog extends StatefulWidget {
  const ContainerReturnDialog({
    super.key,
    required this.containerTypes,
    required this.custody,
    required this.onConfirm,
    this.initialReturns = const {},
    this.title = 'Registrar Retorno de Envases',
    this.message =
        'Ajustá la cantidad de envases vacíos que devuelve el cliente.',
    this.confirmLabel = 'Guardar',
  });

  final List<ContainerType> containerTypes;

  /// Containers the customer holds, by container code.
  final Map<String, int> custody;

  /// Returns per container code to start from; 0 when absent.
  final Map<String, int> initialReturns;

  /// Receives the returns of every shown type, by container code.
  final ValueChanged<Map<String, int>> onConfirm;

  final String title;
  final String message;
  final String confirmLabel;

  @override
  State<ContainerReturnDialog> createState() => _ContainerReturnDialogState();
}

class _ContainerReturnDialogState extends State<ContainerReturnDialog> {
  late final Map<String, int> _returns = {
    for (final type in widget.containerTypes)
      type.code: widget.initialReturns[type.code] ?? 0,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: TextStyle(color: context.marilin.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            for (final type in widget.containerTypes)
              _ReturnRow(
                label: type.label,
                returned: _returns[type.code] ?? 0,
                max: widget.custody[type.code] ?? 0,
                onChanged: (value) =>
                    setState(() => _returns[type.code] = value),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => widget.onConfirm(Map.unmodifiable(_returns)),
          style: FilledButton.styleFrom(
            backgroundColor: MarilinColors.brandBlue,
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _ReturnRow extends StatelessWidget {
  const _ReturnRow({
    required this.label,
    required this.returned,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int returned;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Restar',
                onPressed: returned > 0 ? () => onChanged(returned - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: MarilinColors.destructive,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$returned',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Sumar',
                onPressed: returned < max
                    ? () => onChanged(returned + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: MarilinColors.brandBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
