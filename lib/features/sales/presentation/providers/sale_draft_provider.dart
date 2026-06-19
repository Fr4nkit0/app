import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/history/presentation/providers/history_repository_provider.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/presentation/providers/register_sale_usecase_provider.dart';

class SaleDraft extends Notifier<SaleDraftState> {
  @override
  SaleDraftState build() => const SaleDraftState();

  void selectCustomer(Customer customer, {String? visitId}) {
    state = state.copyWith(customer: customer, visitId: visitId);
  }

  void clearCustomer() {
    state = state.copyWith(clearCustomer: true, clearRouteStopId: true);
  }

  void setQuantity(SaleItem item, int quantity) {
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

    final updatedReturns = Map<String, int>.from(state.returnedContainers);
    for (final type in ['BIDON_20L', 'SIFON_2L']) {
      final delivered = newItems
          .where((i) => i.product.containerType == type)
          .fold(0, (sum, i) => sum + i.quantity);
      if (delivered > 0) {
        updatedReturns[type] = delivered;
      } else {
        updatedReturns.remove(type);
      }
    }

    state = state.copyWith(items: newItems, returnedContainers: updatedReturns);
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

    await ref
        .read(registerSaleUseCaseProvider)
        .execute(sale, containerMovements: movements);

    // TODO: when paymentMethod == credit, update customer.debtAmount by draft.total.
    // Deferred: Customer is immutable without copyWith and CustomerRepository
    // has no addDebt method in this iteration (decision #302). Do NOT touch
    // lib/features/customers/ until the debt-sync feature is scoped.

    final description = draft.items
        .map((i) => '${i.quantity} ${i.product.unitLabel}')
        .join(' · ');

    await ref
        .read(historyRepositoryProvider)
        .addEntry(
          HistoryEntry(
            id: const Uuid().v4(),
            type: HistoryEntryType.sale,
            customer: draft.customer!,
            date: DateTime.now(),
            amount: draft.total,
            description: description,
          ),
        );

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
