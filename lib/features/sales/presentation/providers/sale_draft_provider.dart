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
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';

class SaleDraft extends Notifier<SaleDraftState> {
  @override
  SaleDraftState build() => const SaleDraftState();

  void selectCustomer(Customer customer, {String? routeStopId}) {
    state = state.copyWith(customer: customer, routeStopId: routeStopId);
  }

  void clearCustomer() {
    state = state.copyWith(clearCustomer: true, clearRouteStopId: true);
  }

  void setQuantity(SaleItem item, int quantity) {
    if (quantity <= 0) {
      state = state.copyWith(
        items: state.items
            .where((i) => i.product.id != item.product.id)
            .toList(),
      );
      return;
    }
    final existing = state.items.indexWhere(
      (i) => i.product.id == item.product.id,
    );
    if (existing >= 0) {
      final updated = List.of(state.items);
      updated[existing] = SaleItem(product: item.product, quantity: quantity);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [...state.items, SaleItem(product: item.product, quantity: quantity)],
      );
    }
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
    state = state.copyWith(
      cashAmount: cash,
      transferAmount: transfer,
    );
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
      routeStopId: draft.routeStopId,
    );

    await ref.read(saleRepositoryProvider).saveSale(sale);

    // TODO: when paymentMethod == credit, update customer.debtAmount by draft.total.
    // Deferred: Customer is immutable without copyWith and CustomerRepository
    // has no addDebt method in this iteration (decision #302). Do NOT touch
    // lib/features/customers/ until the debt-sync feature is scoped.

    final description = draft.items
        .map((i) => '${i.quantity} ${i.product.unitLabel}')
        .join(' · ');

    await ref.read(historyRepositoryProvider).addEntry(
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
final saleDraftProvider =
    NotifierProvider<SaleDraft, SaleDraftState>(SaleDraft.new);
