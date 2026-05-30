import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';

class SaleDraftState {
  final Customer? customer;
  final List<SaleItem> items;
  final PaymentMethod? paymentMethod;
  final double? cashAmount;
  final double? transferAmount;

  const SaleDraftState({
    this.customer,
    this.items = const [],
    this.paymentMethod,
    this.cashAmount,
    this.transferAmount,
  });

  SaleDraftState copyWith({
    Customer? customer,
    List<SaleItem>? items,
    PaymentMethod? paymentMethod,
    double? cashAmount,
    double? transferAmount,
    bool clearCustomer = false,
    bool clearPaymentMethod = false,
    bool clearCashAmount = false,
    bool clearTransferAmount = false,
  }) {
    return SaleDraftState(
      customer: clearCustomer ? null : (customer ?? this.customer),
      items: items ?? this.items,
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      cashAmount: clearCashAmount ? null : (cashAmount ?? this.cashAmount),
      transferAmount:
          clearTransferAmount ? null : (transferAmount ?? this.transferAmount),
    );
  }

  double get total =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get mixedTotal => (cashAmount ?? 0) + (transferAmount ?? 0);

  bool get isValidPayment {
    if (paymentMethod == null) return false;
    switch (paymentMethod!) {
      case PaymentMethod.mixed:
        return (mixedTotal - total).abs() <= 0.01;
      case PaymentMethod.credit:
        return true;
      case PaymentMethod.cash:
      case PaymentMethod.transfer:
      case PaymentMethod.route:
        return true;
    }
  }

  double get remaining =>
      paymentMethod == PaymentMethod.mixed ? (total - mixedTotal) : 0;

  bool get canProceedToStep3 =>
      customer != null && items.isNotEmpty;

  bool get canConfirm =>
      customer != null &&
      items.isNotEmpty &&
      paymentMethod != null &&
      isValidPayment;
}
