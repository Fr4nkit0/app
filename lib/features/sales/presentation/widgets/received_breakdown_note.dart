import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/theme/sales_tokens.dart';
import 'package:app/core/utils/money_formatter.dart';
import 'package:app/features/sales/domain/models/received_breakdown.dart';

/// Where the money received goes, right before confirming (S2):
/// "Recibido $8.000", "Venta $6.500 · Deuda $1.500" and what the account is
/// left at, "Deuda restante $31.000" or "Saldo a favor $2.000".
///
/// Presentational: the caller decides when it applies.
class ReceivedBreakdownNote extends StatelessWidget {
  const ReceivedBreakdownNote({super.key, required this.breakdown});

  final ReceivedBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final figures = tokens.tabularStyle.fontFeatures;
    final muted = context.marilin.textMuted;
    final after = breakdown.balanceAfter;
    final parts = [
      'Venta ${formatMoney(breakdown.sale)}',
      if (breakdown.debt > 0) 'Deuda ${formatMoney(breakdown.debt)}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recibido ${formatMoney(breakdown.received)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.marilin.ink,
            fontFeatures: figures,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          parts.join(' · '),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: muted,
            fontFeatures: figures,
          ),
        ),
        Text(
          after > 0
              ? 'Deuda restante ${formatMoney(after)}'
              : after < 0
              ? 'Saldo a favor ${formatMoney(-after)}'
              : 'Queda al día',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: after < 0 ? tokens.primary : muted,
            fontFeatures: figures,
          ),
        ),
      ],
    );
  }
}
