import 'package:flutter/material.dart';

import 'package:app/features/sales/domain/models/payment_method.dart';

IconData paymentMethodIcon(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.cash:
      return Icons.payments_rounded;
    case PaymentMethod.transfer:
      return Icons.account_balance_rounded;
    case PaymentMethod.mixed:
      return Icons.call_split_rounded;
    case PaymentMethod.credit:
      return Icons.event_note_rounded;
    case PaymentMethod.route:
      return Icons.local_shipping_rounded;
  }
}
