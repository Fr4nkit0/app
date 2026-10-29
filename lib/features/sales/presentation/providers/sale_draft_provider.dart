import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/inventory/domain/custody.dart';
import 'package:uuid/uuid.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/register_sale_usecase_provider.dart';

class SaleDraft extends Notifier<SaleDraftState> {
  @override
  SaleDraftState build() => const SaleDraftState();

  void selectCustomer(Customer customer, {String? visitId}) {
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
    // each type as the sale delivers.
    final next = state.copyWith(items: newItems);
    state = next.copyWith(
      returnedContainers: deliveredByContainerType(next.containerDeliveries),
    );
  }

  void setReturnedQuantity(String type, int quantity) {
    if (quantity < 0) return;
    final updated = Map<String, int>.from(state.returnedContainers);
    updated[type] = quantity;
    state = state.copyWith(returnedContainers: updated);
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

  void setMixedAmounts({double? cash, double? transfer}) {
    state = state.copyWith(cashAmount: cash, transferAmount: transfer);
  }

  Future<void> commit() async {
    final draft = state;
    if (!draft.canConfirm) return;

    final isMixed = draft.paymentMethod == PaymentMethod.mixed;

    final sale = Sale(
      id: const Uuid().v4(),
      customer: draft.customer!,
      items: draft.items,
      total: draft.total,
      paymentMethod: draft.paymentMethod!,
      date: DateTime.now(),
      cashAmount: isMixed ? draft.cashAmount : null,
      transferAmount: isMixed ? draft.transferAmount : null,
      visitId: draft.visitId,
    );

    final movements = draft.toContainerMovements(
      draft.customer!.id,
      draft.visitId,
    );

    // A failed sale throws and keeps the draft so the driver can retry.
    await ref
        .read(registerSaleUseCaseProvider)
        .execute(sale, containerMovements: movements);

    // The customer balance moves with the sale and its settling payments
    // (see CustomerAccount); nothing to update here.

    state = const SaleDraftState();
  }

  void reset() {
    state = const SaleDraftState();
  }
}

// NOT autoDispose — draft must survive navigation between steps
final saleDraftProvider = NotifierProvider<SaleDraft, SaleDraftState>(
  SaleDraft.new,
);
