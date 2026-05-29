import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';

class SaleDraftState {
  final Customer? customer;
  final List<SaleItem> items;
  final PaymentMethod? paymentMethod;

  const SaleDraftState({
    this.customer,
    this.items = const [],
    this.paymentMethod,
  });

  SaleDraftState copyWith({
    Customer? customer,
    List<SaleItem>? items,
    PaymentMethod? paymentMethod,
    bool clearCustomer = false,
    bool clearPaymentMethod = false,
  }) {
    return SaleDraftState(
      customer: clearCustomer ? null : (customer ?? this.customer),
      items: items ?? this.items,
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
    );
  }

  double get total =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);

  bool get canProceedToStep3 =>
      customer != null && items.isNotEmpty;

  bool get canConfirm =>
      customer != null && items.isNotEmpty && paymentMethod != null;
}
