import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/inventory/domain/custody.dart';
import 'package:uuid/uuid.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/register_sale_usecase_provider.dart';

class SaleDraft extends Notifier<SaleDraftState> {
  @override
  SaleDraftState build() => const SaleDraftState();

  /// The lines go when the customer changes, since they were priced with
  /// the previous customer's agreements.
  void selectCustomer(Customer customer, {String? visitId}) {
    if (state.customer case final previous? when previous.id != customer.id) {
      clearCustomer();
    }
    state = state.copyWith(customer: customer, visitId: visitId);
  }

  /// Lines were priced for the previous customer's agreements, so they go
  /// with it.
  void clearCustomer() {
    state = state.copyWith(
      clearCustomer: true,
      clearRouteStopId: true,
      items: const [],
      returnedContainers: const {},
      skeletonDelivered: 0,
      skeletonReturned: 0,
    );
  }

  static const maxQuantity = 999;

  void setQuantity(SaleItem item, int requested) {
    final quantity = requested.clamp(0, maxQuantity);
    if (quantity > 0 && !item.product.hasPrice) return;
    List<SaleItem> newItems;
    if (quantity <= 0) {
      newItems = state.items
          .where((i) => i.product.id != item.product.id)
          .toList();
    } else {
      final existing = state.items.indexWhere(
        (i) => i.product.id == item.product.id,
      );
      if (existing >= 0) {
        final updated = List.of(state.items);
        updated[existing] = SaleItem(product: item.product, quantity: quantity);
        newItems = updated;
      } else {
        newItems = [
          ...state.items,
          SaleItem(product: item.product, quantity: quantity),
        ];
      }
    }

    // Custody rule: by default the customer returns as many containers of
    // each type as the sale delivers. A cash or transfer amount starts
    // again at the new total.
    final singleMethod =
        state.paymentMethod == PaymentMethod.cash ||
        state.paymentMethod == PaymentMethod.transfer;
    final next = state.copyWith(
      items: newItems,
      clearCashAmount: singleMethod,
      clearTransferAmount: singleMethod,
    );
    state = next.copyWith(
      returnedContainers: deliveredByContainerType(next.containerDeliveries),
    );
  }

  /// Brings the lines to the customer's current prices: an agreement created
  /// changed or deleted during the sale applies to what is already loaded.
  /// A line left without a price (its agreement is gone and the product has
  /// no list price) leaves the sale, since it cannot be sold; a line whose
  /// product is not in [products] stays as it was.
  void repriceItems(List<Product> products) {
    final current = {for (final p in products) p.id: p};
    final items = <SaleItem>[];
    var repriced = false;
    for (final item in state.items) {
      final product = current[item.product.id];
      if (product == null || !_pricedDifferently(item.product, product)) {
        items.add(item);
        continue;
      }
      repriced = true;
      if (product.hasPrice) {
        items.add(SaleItem(product: product, quantity: item.quantity));
      }
    }
    if (!repriced) return;
    final removed = items.length != state.items.length;
    // A cash or transfer amount starts again at the new total.
    final singleMethod =
        state.paymentMethod == PaymentMethod.cash ||
        state.paymentMethod == PaymentMethod.transfer;
    final next = state.copyWith(
      items: items,
      clearCashAmount: singleMethod,
      clearTransferAmount: singleMethod,
    );
    // Custody rule (see [setQuantity]) only when a delivery went away.
    state = removed
        ? next.copyWith(
            returnedContainers: deliveredByContainerType(
              next.containerDeliveries,
            ),
          )
        : next;
  }

  static bool _pricedDifferently(Product a, Product b) =>
      a.price != b.price ||
      a.agreementId != b.agreementId ||
      a.agreementUuid != b.agreementUuid;

  void setReturnedQuantity(String type, int quantity) {
    if (quantity < 0) return;
    final updated = Map<String, int>.from(state.returnedContainers);
    updated[type] = quantity;
    state = state.copyWith(returnedContainers: updated);
  }

  /// Skeletons lent with this sale, from 0 to [maxQuantity].
  void setSkeletonDelivered(int quantity) {
    state = state.copyWith(skeletonDelivered: quantity.clamp(0, maxQuantity));
  }

  /// Skeletons taken back with this sale, from 0 to [maxQuantity]; the
  /// customer's custody does not cap it.
  void setSkeletonReturned(int quantity) {
    state = state.copyWith(skeletonReturned: quantity.clamp(0, maxQuantity));
  }

  void setPaymentMethod(PaymentMethod method) {
    // Always clear split amounts when changing method.
    // If the new method is mixed, the user will fill them in; if not, they are stale.
    state = state.copyWith(
      paymentMethod: method,
      clearCashAmount: true,
      clearTransferAmount: true,
    );
  }

  /// What the customer hands over on a cash or transfer sale: below the
  /// total the rest stays as their debt, above it the rest pays previous
  /// debt and then stays as credit (S2). Null (an empty or invalid amount)
  /// counts as 0, which cannot confirm.
  void setCollectedAmount(double? amount) {
    final collected = amount ?? 0;
    switch (state.paymentMethod) {
      case PaymentMethod.cash:
        state = state.copyWith(cashAmount: collected);
      case PaymentMethod.transfer:
        state = state.copyWith(transferAmount: collected);
      case _:
        return;
    }
  }

  void setMixedAmounts({double? cash, double? transfer}) {
    state = state.copyWith(cashAmount: cash, transferAmount: transfer);
  }

  Future<void> commit() async {
    final draft = state;
    if (!draft.canConfirm) return;

    final method = draft.paymentMethod!;
    final isMixed = method == PaymentMethod.mixed;
    // A cash or transfer sale carries its amount only when partial; paid in
    // full, with or without money beyond it, it is saved as before and the
    // use case books the extra on the customer's account.
    final partial = draft.isPartialPayment;

    final sale = Sale(
      id: const Uuid().v4(),
      customer: draft.customer!,
      items: draft.items,
      total: draft.total,
      paymentMethod: method,
      date: DateTime.now(),
      cashAmount: isMixed || (partial && method == PaymentMethod.cash)
          ? draft.cashAmount
          : null,
      transferAmount: isMixed || (partial && method == PaymentMethod.transfer)
          ? draft.transferAmount
          : null,
      visitId: draft.visitId,
    );

    final movements = draft.toContainerMovements(
      draft.customer!.id,
      draft.visitId,
    );

    // A failed sale throws and keeps the draft so the driver can retry.
    await ref
        .read(registerSaleUseCaseProvider)
        .execute(
          sale,
          containerMovements: movements,
          debtAmount: draft.extraReceived,
        );

    // The customer balance moves with the sale and its settling payments
    // (see CustomerAccount); nothing to update here.

    state = const SaleDraftState();
  }

  /// Safe after the provider is gone: a pushed sale screen resets the draft
  /// a microtask after it is disposed, maybe with the whole app torn down.
  void reset() {
    if (!ref.mounted) return;
    state = const SaleDraftState();
  }
}

// NOT autoDispose — draft must survive navigation between steps
final saleDraftProvider = NotifierProvider<SaleDraft, SaleDraftState>(
  SaleDraft.new,
);
