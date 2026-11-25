import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/inventory/domain/models/truck_skeletons.dart';

/// Most skeletons the driver can deliver or take back at once.
const maxSkeletons = 999;

/// Skeletons delivered and taken back, each from 0 to [maxSkeletons].
/// Taking back is not capped by the customer's [balance]: the office
/// corrects a balance below zero.
class SkeletonExchange extends StatelessWidget {
  const SkeletonExchange({
    super.key,
    required this.delivered,
    required this.returned,
    required this.onDeliveredChanged,
    required this.onReturnedChanged,
  });

  final int delivered;
  final int returned;
  final ValueChanged<int> onDeliveredChanged;
  final ValueChanged<int> onReturnedChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonCountRow(
          label: 'Entregar al cliente',
          value: delivered,
          onChanged: onDeliveredChanged,
        ),
        SkeletonCountRow(
          label: 'Retirar del cliente',
          value: returned,
          onChanged: onReturnedChanged,
        ),
      ],
    );
  }
}

/// The customer's skeleton balance, as the section shows it.
String skeletonBalanceLabel(int balance) => 'Saldo del cliente: $balance';

/// What is left on the truck before this exchange. Turns the destructive
/// color when [delivered] (less what is [returned]) goes past it; it only
/// warns, the delivery is never blocked.
class SkeletonTruckLabel extends StatelessWidget {
  const SkeletonTruckLabel({
    super.key,
    required this.truck,
    required this.delivered,
    required this.returned,
  });

  final TruckSkeletons truck;
  final int delivered;
  final int returned;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;
    final short = truck.runsShort(delivered: delivered, returned: returned);
    return Text(
      'En el camión: ${truck.remaining}',
      style: TextStyle(
        color: short ? tokens.destructive : tokens.textMuted,
        fontSize: 13,
        fontWeight: short ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}

/// One labelled count with Restar and Sumar buttons.
class SkeletonCountRow extends StatelessWidget {
  const SkeletonCountRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          IconButton(
            tooltip: 'Restar',
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: MarilinColors.destructive,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Sumar',
            onPressed: value < maxSkeletons ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: MarilinColors.brandBlue,
          ),
        ],
      ),
    );
  }
}
