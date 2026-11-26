import 'package:app/features/payments/domain/models/sale_debt_allocation.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
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

  /// The cash part of a mixed payment, or what a cash sale collects; null
  /// on a cash sale means its whole [total] (see [collectedAmount]).
  final double? cashAmount;

  /// The transfer part of a mixed payment, or what a transfer sale
  /// collects; null on a transfer sale means its whole [total].
  final double? transferAmount;
  final Map<String, int> returnedContainers;

  /// Skeletons ([ContainerType.skeletonCode]) lent with this sale. No sale
  /// line carries them: the driver sets them by hand.
  final int skeletonDelivered;

  /// Skeletons taken back with this sale; not capped by the customer's
  /// custody, the office corrects a balance below zero.
  final int skeletonReturned;

  /// Whether the driver also collects previous debt with this sale.
  final bool collectDebt;

  /// How much previous debt is collected while [collectDebt] is on; null
  /// while the driver has not typed a valid amount.
  final double? debtAmount;

  /// What the customer owed when the driver switched [collectDebt] on; the
  /// [debtAmount] cannot go above it.
  final double currentDebt;

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
    this.collectDebt = false,
    this.debtAmount,
    this.currentDebt = 0,
  });

  /// The methods that can also collect previous debt: the money is handed
  /// over on the spot.
  static const debtMethods = {
    PaymentMethod.cash,
    PaymentMethod.transfer,
    PaymentMethod.mixed,
  };

  /// Largest difference between amounts that still counts as equal.
  static const tolerance = 0.01;

  SaleDraftState copyWith({
    Customer? customer,
    String? visitId,
    List<SaleItem>? items,
    PaymentMethod? paymentMethod,
    double? cashAmount,
    double? transferAmount,
    Map<String, int>? returnedContainers,
    int? skeletonDelivered,
    int? skeletonReturned,
    bool? collectDebt,
    double? debtAmount,
    double? currentDebt,
    bool clearCustomer = false,
    bool clearRouteStopId = false,
    bool clearPaymentMethod = false,
    bool clearCashAmount = false,
    bool clearTransferAmount = false,
    bool clearDebtAmount = false,
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
      collectDebt: collectDebt ?? this.collectDebt,
      debtAmount: clearDebtAmount ? null : (debtAmount ?? this.debtAmount),
      currentDebt: currentDebt ?? this.currentDebt,
    );
  }

  /// Nothing the driver would miss: no customer and no lines.
  bool get isEmpty => customer == null && items.isEmpty;

  /// Leaving the sale asks first only when products were loaded; a chosen
  /// customer alone is not worth a prompt.
  bool get needsDiscardConfirmation => items.isNotEmpty;

  double get total => items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get mixedTotal => (cashAmount ?? 0) + (transferAmount ?? 0);

  /// Whether previous debt is collected with this sale: switched on, paid
  /// by one of the [debtMethods] and, for cash or transfer, with the whole
  /// sale collected (S3: a partial payment collects no previous debt).
  bool get collectsDebt =>
      collectDebt &&
      debtMethods.contains(paymentMethod) &&
      !_lowersSingleMethodAmount;

  /// A cash or transfer amount below the [total].
  bool get _lowersSingleMethodAmount =>
      (paymentMethod == PaymentMethod.cash ||
          paymentMethod == PaymentMethod.transfer) &&
      collectedAmount < total - tolerance;

  /// The previous debt collected with this sale; 0 when none is.
  double get debtToCollect => collectsDebt ? (debtAmount ?? 0) : 0;

  /// What the driver collects: the sale plus the debt collected with it.
  double get operationTotal => total + debtToCollect;

  /// The debt amount is above 0 and not above [currentDebt]; always true
  /// while no debt is collected.
  bool get isValidDebtAmount {
    if (!collectsDebt) return true;
    final amount = debtAmount;
    return amount != null && amount > 0 && amount <= currentDebt + tolerance;
  }

  /// What the customer hands over for the sale itself: a cash or transfer
  /// sale's amount (the whole [total] until the driver lowers it), the sum
  /// of a mixed payment's parts; 0 for credit and route.
  double get collectedAmount => switch (paymentMethod) {
    PaymentMethod.cash => cashAmount ?? total,
    PaymentMethod.transfer => transferAmount ?? total,
    PaymentMethod.mixed => mixedTotal,
    PaymentMethod.credit || PaymentMethod.route || null => 0,
  };

  /// What the customer is left owing from this sale paid on the spot
  /// ([total] − [collectedAmount]); 0 for credit and route, which are not
  /// paid on the spot, and while previous debt is collected, which needs
  /// the sale paid in full.
  double get unpaidAmount {
    if (!debtMethods.contains(paymentMethod) || collectsDebt) return 0;
    final unpaid = total - collectedAmount;
    return unpaid > 0 ? unpaid : 0;
  }

  /// Whether the customer pays part of the sale on the spot and owes the
  /// rest; a mixed payment with nothing typed yet is not partial.
  bool get isPartialPayment => collectedAmount > 0 && unpaidAmount > tolerance;

  /// A sale paid on the spot without previous debt collects more than 0
  /// and at most its [total].
  bool get _isValidCollectedAmount =>
      collectedAmount > 0 && collectedAmount <= total + tolerance;

  bool get isValidPayment {
    if (paymentMethod == null) return false;
    switch (paymentMethod!) {
      case PaymentMethod.mixed:
        // With debt, the allocation's tolerance decides: a split it would
        // reject must not reach the confirm button.
        if (collectsDebt) {
          return (mixedTotal - operationTotal).abs() <=
              SaleDebtAllocation.tolerance;
        }
        return _isValidCollectedAmount;
      case PaymentMethod.cash:
      case PaymentMethod.transfer:
        return collectsDebt || _isValidCollectedAmount;
      case PaymentMethod.credit:
      case PaymentMethod.route:
        return true;
    }
  }

  double get remaining =>
      paymentMethod == PaymentMethod.mixed ? (operationTotal - mixedTotal) : 0;

  bool get canProceedToStep3 => customer != null && items.isNotEmpty;

  bool get canConfirm =>
      customer != null &&
      items.isNotEmpty &&
      paymentMethod != null &&
      isValidPayment &&
      isValidDebtAmount;

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
