enum PaymentMethod {
  cash,
  transfer,
  mixed,
  credit,
  route;

  static const List<PaymentMethod> gridMethods = [
    PaymentMethod.cash,
    PaymentMethod.transfer,
    PaymentMethod.mixed,
    PaymentMethod.credit,
  ];
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.mixed:
        return 'Mixto';
      case PaymentMethod.credit:
        return 'A crédito';
      case PaymentMethod.route:
        return 'Rinde Ruta';
    }
  }
}
