import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/inventory/domain/models/container_exchange.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/domain/models/truck_skeletons.dart';
import 'package:app/features/inventory/presentation/widgets/skeleton_exchange.dart';

/// The catalog carries no icon: types alternate the jug and bottle icons in
/// catalog order.
IconData containerTypeIcon(int position) =>
    position.isEven ? Icons.water_drop_outlined : Icons.local_drink_outlined;

/// Asks how many containers of each type the customer hands back; each type
/// goes from 0 up to the customer's [custody] of it. The skeleton
/// ([ContainerType.skeletonCode]) is also delivered, and its return is not
/// capped: the office corrects a balance below zero.
class ContainerReturnDialog extends StatefulWidget {
  const ContainerReturnDialog({
    super.key,
    required this.containerTypes,
    required this.custody,
    required this.onConfirm,
    this.initialReturns = const {},
    this.truckSkeletons,
    this.title = 'Registrar Retorno de Envases',
    this.message =
        'Ajustá la cantidad de envases vacíos que devuelve el cliente.',
    this.confirmLabel = 'Guardar',
  });

  final List<ContainerType> containerTypes;

  /// Containers the customer holds, by container code.
  final Map<String, int> custody;

  /// Returns per container code to start from; 0 when absent. Values above
  /// the customer's [custody] start at the custody.
  final Map<String, int> initialReturns;

  /// The skeletons left on the truck of today's route, shown with the
  /// skeleton; null hides them.
  final TruckSkeletons? truckSkeletons;

  /// Receives the returns of every shown type and the skeletons delivered,
  /// by container code.
  final ValueChanged<ContainerExchange> onConfirm;

  final String title;
  final String message;
  final String confirmLabel;

  @override
  State<ContainerReturnDialog> createState() => _ContainerReturnDialogState();
}

class _ContainerReturnDialogState extends State<ContainerReturnDialog> {
  static bool _isSkeleton(ContainerType type) =>
      type.code == ContainerType.skeletonCode;

  late final Map<String, int> _returns = {
    for (final type in widget.containerTypes)
      type.code: (widget.initialReturns[type.code] ?? 0).clamp(
        0,
        _isSkeleton(type) ? maxSkeletons : widget.custody[type.code] ?? 0,
      ),
  };

  late final bool _lendsSkeleton = widget.containerTypes.any(_isSkeleton);
  int _skeletonDelivered = 0;

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
              if (_isSkeleton(type))
                _SkeletonBlock(
                  balance: widget.custody[type.code] ?? 0,
                  truck: widget.truckSkeletons,
                  delivered: _skeletonDelivered,
                  returned: _returns[type.code] ?? 0,
                  onDeliveredChanged: (value) =>
                      setState(() => _skeletonDelivered = value),
                  onReturnedChanged: (value) =>
                      setState(() => _returns[type.code] = value),
                )
              else
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
          onPressed: () => widget.onConfirm((
            returns: Map.unmodifiable(_returns),
            deliveries: Map.unmodifiable({
              if (_lendsSkeleton && _skeletonDelivered > 0)
                ContainerType.skeletonCode: _skeletonDelivered,
            }),
          )),
          style: FilledButton.styleFrom(
            backgroundColor: MarilinColors.brandBlue,
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// The skeleton: delivered and taken back, with the customer's balance and
/// what is left on the truck.
class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.balance,
    required this.truck,
    required this.delivered,
    required this.returned,
    required this.onDeliveredChanged,
    required this.onReturnedChanged,
  });

  final int balance;
  final TruckSkeletons? truck;
  final int delivered;
  final int returned;
  final ValueChanged<int> onDeliveredChanged;
  final ValueChanged<int> onReturnedChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Esqueleto',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            skeletonBalanceLabel(balance),
            style: TextStyle(color: context.marilin.textMuted, fontSize: 13),
          ),
          if (truck case final truck?)
            SkeletonTruckLabel(
              truck: truck,
              delivered: delivered,
              returned: returned,
            ),
          SkeletonExchange(
            delivered: delivered,
            returned: returned,
            onDeliveredChanged: onDeliveredChanged,
            onReturnedChanged: onReturnedChanged,
          ),
        ],
      ),
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
