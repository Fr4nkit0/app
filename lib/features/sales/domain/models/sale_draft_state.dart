import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:uuid/uuid.dart';

class SaleDraftState {
  final Customer? customer;
  final String? visitId;
  final List<SaleItem> items;
  final PaymentMethod? paymentMethod;
  final double? cashAmount;
  final double? transferAmount;
  final Map<String, int> returnedContainers;

  const SaleDraftState({
    this.customer,
    this.visitId,
    this.items = const [],
    this.paymentMethod,
    this.cashAmount,
    this.transferAmount,
    this.returnedContainers = const {},
  });

  SaleDraftState copyWith({
    Customer? customer,
    String? visitId,
    List<SaleItem>? items,
    PaymentMethod? paymentMethod,
    double? cashAmount,
    double? transferAmount,
    Map<String, int>? returnedContainers,
    bool clearCustomer = false,
    bool clearRouteStopId = false,
    bool clearPaymentMethod = false,
    bool clearCashAmount = false,
    bool clearTransferAmount = false,
  }) {
    return SaleDraftState(
      customer: clearCustomer ? null : (customer ?? this.customer),
      visitId: clearRouteStopId ? null : (visitId ?? this.visitId),
      items: items ?? this.items,
      paymentMethod: clearPaymentMethod
          ? null
          : (paymentMethod ?? this.paymentMethod),
      cashAmount: clearCashAmount ? null : (cashAmount ?? this.cashAmount),
      transferAmount: clearTransferAmount
          ? null
          : (transferAmount ?? this.transferAmount),
      returnedContainers: returnedContainers ?? this.returnedContainers,
    );
  }

  double get total => items.fold(0.0, (sum, item) => sum + item.subtotal);

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

  bool get canProceedToStep3 => customer != null && items.isNotEmpty;

  bool get canConfirm =>
      customer != null &&
      items.isNotEmpty &&
      paymentMethod != null &&
      isValidPayment;

  List<ContainerMovement> toContainerMovements(
    String customerId,
    String? visitId,
  ) {
    final movements = <ContainerMovement>[];
    for (final type in ['BIDON_20L', 'SIFON_2L']) {
      final delivered = items
          .where((item) => item.product.containerType == type)
          .fold(0, (sum, item) => sum + item.quantity);
      final returned = returnedContainers[type] ?? 0;
      if (delivered > 0 || returned > 0) {
        movements.add(
          ContainerMovement(
            id: const Uuid().v4(),
            customerId: customerId,
            containerType: type,
            deliveredQuantity: delivered,
            returnedQuantity: returned,
            createdAt: DateTime.now(),
            visitId: visitId,
          ),
        );
      }
    }
    return movements;
  }
}
