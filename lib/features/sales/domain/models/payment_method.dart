enum PaymentMethod { cash, transfer, route }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.route:
        return 'Rinde Ruta';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.cash:
        return '💵';
      case PaymentMethod.transfer:
        return '📱';
      case PaymentMethod.route:
        return '🚛';
    }
  }
}
