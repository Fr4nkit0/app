import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/received_breakdown.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/inventory/domain/custody.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:uuid/uuid.dart';

class SaleDraftState {
  final Customer? customer;
  final String? visitId;
  final List<SaleItem> items;
  final PaymentMethod? paymentMethod;

  /// The cash part of a mixed payment, or what the customer hands over on a
  /// cash sale; null on a cash sale means its whole [total] (see
  /// [collectedAmount]).
  final int? cashAmount;

  /// The transfer part of a mixed payment, or what the customer hands over
  /// on a transfer sale; null on a transfer sale means its whole [total].
  final int? transferAmount;
  final Map<String, int> returnedContainers;

  /// Skeletons ([ContainerType.skeletonCode]) lent with this sale. No sale
  /// line carries them: the driver sets them by hand.
  final int skeletonDelivered;

  /// Skeletons taken back with this sale; not capped by the customer's
  /// custody, the office corrects a balance below zero.
  final int skeletonReturned;

  const SaleDraftState({
    this.customer,
    this.visitId,
    this.items = const [],
    this.paymentMethod,
    this.cashAmount,
    this.transferAmount,
    this.returnedContainers = const {},
    this.skeletonDelivered = 0,
    this.skeletonReturned = 0,
  });

  /// The methods paid on the spot: the money handed over pays the sale and,
  /// beyond it, previous debt (S2).
  static const debtMethods = {
    PaymentMethod.cash,
    PaymentMethod.transfer,
    PaymentMethod.mixed,
  };

  SaleDraftState copyWith({
    Customer? customer,
    String? visitId,
    List<SaleItem>? items,
    PaymentMethod? paymentMethod,
    int? cashAmount,
    int? transferAmount,
    Map<String, int>? returnedContainers,
    int? skeletonDelivered,
    int? skeletonReturned,
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
      skeletonDelivered: skeletonDelivered ?? this.skeletonDelivered,
      skeletonReturned: skeletonReturned ?? this.skeletonReturned,
    );
  }

  /// Nothing the driver would miss: no customer and no lines.
  bool get isEmpty => customer == null && items.isEmpty;

  /// Leaving the sale asks first only when products were loaded; a chosen
  /// customer alone is not worth a prompt.
  bool get needsDiscardConfirmation => items.isNotEmpty;

  int get total => items.fold(0, (sum, item) => sum + item.subtotal);

  int get mixedTotal => (cashAmount ?? 0) + (transferAmount ?? 0);

  /// What the customer hands over: a cash or transfer sale's amount (the
  /// whole [total] until the driver changes it), the sum of a mixed
  /// payment's parts; 0 for credit and route.
  int get collectedAmount => switch (paymentMethod) {
    PaymentMethod.cash => cashAmount ?? total,
    PaymentMethod.transfer => transferAmount ?? total,
    PaymentMethod.mixed => mixedTotal,
    PaymentMethod.credit || PaymentMethod.route || null => 0,
  };

  /// What the customer hands over beyond the sale [total]: it pays previous
  /// debt and, past the whole debt, stays as credit in their favor (S2).
  /// 0 for credit and route and for a partial payment.
  int get extraReceived {
    if (!debtMethods.contains(paymentMethod)) return 0;
    final extra = collectedAmount - total;
    return extra > 0 ? extra : 0;
  }

  /// How [collectedAmount] splits between the sale, the previous debt and
  /// credit for an account at [balance] before this sale.
  ReceivedBreakdown receivedBreakdown(int balance) => ReceivedBreakdown.of(
    received: collectedAmount,
    saleTotal: total,
    balance: balance,
  );

  /// What the customer is left owing from this sale paid on the spot
  /// ([total] − [collectedAmount]); 0 for credit and route, which are not
  /// paid on the spot.
  int get unpaidAmount {
    if (!debtMethods.contains(paymentMethod)) return 0;
    final unpaid = total - collectedAmount;
    return unpaid > 0 ? unpaid : 0;
  }

  /// Whether the customer pays part of the sale on the spot and owes the
  /// rest; a mixed payment with nothing typed yet is not partial.
  bool get isPartialPayment => collectedAmount > 0 && unpaidAmount > 0;

  /// A sale paid on the spot needs something handed over; any amount above
  /// the [total] pays previous debt or stays as credit.
  bool get isValidPayment => switch (paymentMethod) {
    null => false,
    PaymentMethod.cash ||
    PaymentMethod.transfer ||
    PaymentMethod.mixed => collectedAmount > 0,
    PaymentMethod.credit || PaymentMethod.route => true,
  };

  /// What a mixed payment still lacks to cover the sale [total]; negative
  /// when it hands over more.
  int get remaining =>
      paymentMethod == PaymentMethod.mixed ? (total - mixedTotal) : 0;

  bool get canProceedToStep3 => customer != null && items.isNotEmpty;

  bool get canConfirm =>
      customer != null &&
      items.isNotEmpty &&
      paymentMethod != null &&
      isValidPayment;

  /// The sale lines as container deliveries, for the custody rules.
  Iterable<({String? containerType, int quantity})> get containerDeliveries =>
      items.map(
        (item) => (
          containerType: item.product.containerType,
          quantity: item.quantity,
        ),
      );

  List<ContainerMovement> toContainerMovements(
    String customerId,
    String? visitId,
  ) {
    final deliveredByType = deliveredByContainerType(containerDeliveries);
    const skeleton = ContainerType.skeletonCode;
    final returnedByType = {
      ...returnedContainers,
      if (skeletonReturned > 0)
        skeleton: (returnedContainers[skeleton] ?? 0) + skeletonReturned,
    };
    if (skeletonDelivered > 0) {
      deliveredByType[skeleton] =
          (deliveredByType[skeleton] ?? 0) + skeletonDelivered;
    }
    final movements = <ContainerMovement>[];
    for (final type in {...deliveredByType.keys, ...returnedByType.keys}) {
      final delivered = deliveredByType[type] ?? 0;
      final returned = returnedByType[type] ?? 0;
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
