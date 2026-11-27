import 'package:uuid/uuid.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/models/payment_split.dart';
import 'package:app/features/payments/domain/models/sale_debt_allocation.dart';
import 'package:app/features/sales/data/repositories/sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';

class RegisterSaleUseCase {
  const RegisterSaleUseCase({
    required SaleRepository saleRepo,
    required PaymentRepository paymentRepo,
    required InventoryRepository inventoryRepo,
    required TransactionRunner transaction,
  }) : _saleRepo = saleRepo,
       _paymentRepo = paymentRepo,
       _inventoryRepo = inventoryRepo,
       _transaction = transaction;

  final SaleRepository _saleRepo;
  final PaymentRepository _paymentRepo;
  final InventoryRepository _inventoryRepo;
  final TransactionRunner _transaction;

  /// Records [sale], its settling payments and [containerMovements] (linked
  /// to the sale) in one unit of work. Throws [ValidationFailure] for a sale
  /// without items or whose total does not match its items.
  ///
  /// Without previous debt, a cash or transfer sale is settled by its
  /// [Sale.cashAmount] or [Sale.transferAmount] when it holds one and by its
  /// total otherwise, and a mixed sale by both amounts; together they must be
  /// above 0 and not above the total, and the rest stays on the customer's
  /// account (a partial payment). Throws [ValidationFailure] otherwise.
  ///
  /// A [debtAmount] above 0 means the customer also hands over that much
  /// beyond the sale in the same operation: a cash or transfer sale takes
  /// the total plus [debtAmount] by its method, and the [Sale.cashAmount]
  /// and [Sale.transferAmount] of a mixed sale are what the customer handed
  /// over and must add up to the total plus [debtAmount]; see
  /// [SaleDebtAllocation]. The sale keeps only its own part, the rest is
  /// paid by payments linked to no sale and every payment of a method shares
  /// one transaction uuid. Like the server's running account, [debtAmount]
  /// may go beyond what the customer owes: the rest leaves their balance
  /// negative, credit in their favor (S2). Throws [ValidationFailure] for a
  /// negative [debtAmount], debt with a credit or route sale, a mixed split
  /// that does not cover the sale plus the debt, or a partial cash or
  /// transfer sale.
  Future<void> execute(
    Sale sale, {
    Payment? payment,
    List<ContainerMovement>? containerMovements,
    int debtAmount = 0,
  }) async {
    if (sale.items.isEmpty) {
      throw const ValidationFailure('La venta no tiene productos.');
    }
    final itemsTotal = sale.items.fold<int>(0, (sum, i) => sum + i.subtotal);
    // The server rejects such a sale; it would stay stuck in the outbox.
    if (sale.total != itemsTotal) {
      throw const ValidationFailure(
        'El total de la venta no coincide con sus productos.',
      );
    }
    if (debtAmount < 0) {
      throw const ValidationFailure('La deuda a cobrar no puede ser negativa.');
    }
    if (debtAmount == 0) _checkCollected(sale);
    final (saved, operationPayments) = debtAmount == 0
        ? (sale, settlingPayments(sale))
        : _withDebt(sale, debtAmount);

    await _transaction(() async {
      await _saleRepo.saveSale(saved);

      final payments = [?payment, ...operationPayments];
      if (payments.isNotEmpty) {
        await _paymentRepo.recordPayments(payments);
      }
      if (containerMovements != null) {
        for (final movement in containerMovements) {
          await _inventoryRepo.recordContainerMovement(
            movement.withSale(sale.id),
          );
        }
      }
    });
  }

  /// Without previous debt, a sale paid on the spot collects more than 0 and
  /// at most its total; what it leaves unpaid stays on the customer's
  /// account (a partial payment). Throws [ValidationFailure] otherwise.
  static void _checkCollected(Sale sale) {
    if (!_paidOnTheSpot(sale.paymentMethod)) return;
    final collected = sale.settlement;
    if (collected.cash < 0 || collected.transfer < 0) {
      throw const ValidationFailure('Ingresá montos mayores o iguales a 0.');
    }
    if (collected.total <= 0) {
      throw const ValidationFailure('Ingresá un monto cobrado mayor a \$0.');
    }
    if (collected.total > sale.total) {
      throw const ValidationFailure(
        'Lo cobrado no puede superar el total de la venta.',
      );
    }
  }

  static bool _paidOnTheSpot(PaymentMethod method) => switch (method) {
    PaymentMethod.cash || PaymentMethod.transfer || PaymentMethod.mixed => true,
    PaymentMethod.credit || PaymentMethod.route => false,
  };

  /// [sale] with only its own part of the money, and the payments of the
  /// sale and of [debtAmount] of previous debt. Previous debt is only
  /// collected with a sale paid in full: a partial cash or transfer sale
  /// throws [ValidationFailure].
  static (Sale, List<Payment>) _withDebt(Sale sale, int debtAmount) {
    final isPartial =
        (sale.paymentMethod == PaymentMethod.cash ||
            sale.paymentMethod == PaymentMethod.transfer) &&
        sale.settlement.total < sale.total;
    if (isPartial) {
      throw const ValidationFailure(
        'Para cobrar deuda anterior, cobrá la venta completa.',
      );
    }
    final operationTotal = sale.total + debtAmount;
    final received = switch (sale.paymentMethod) {
      PaymentMethod.cash => PaymentSplit(cash: operationTotal),
      PaymentMethod.transfer => PaymentSplit(transfer: operationTotal),
      PaymentMethod.mixed => sale.settlement,
      PaymentMethod.credit ||
      PaymentMethod.route => throw const ValidationFailure(
        'Solo se puede cobrar deuda en una venta pagada en el momento.',
      ),
    };
    final allocation = SaleDebtAllocation.of(
      received,
      saleTotal: sale.total,
      debtAmount: debtAmount,
    );
    final payments = allocation.toPayments(
      customerId: sale.customer.id,
      at: sale.date,
      saleId: sale.id,
      saleIdFor: (i) => _salePaymentId(sale.id, i),
      debtIdFor: (i) =>
          _uuid.v5(Namespace.url.value, 'sale-debt-payment/${sale.id}/$i'),
      transactionUuidFor: (type) => _uuid.v5(
        Namespace.url.value,
        'sale-transaction/${sale.id}/${type.dbValue}',
      ),
      visitId: sale.visitId,
    );
    final saved = sale.paymentMethod == PaymentMethod.mixed
        ? Sale(
            id: sale.id,
            customer: sale.customer,
            items: sale.items,
            total: sale.total,
            paymentMethod: sale.paymentMethod,
            date: sale.date,
            cashAmount: allocation.sale.cash,
            transferAmount: allocation.sale.transfer,
            visitId: sale.visitId,
            isCancelled: sale.isCancelled,
          )
        : sale;
    return (saved, [...payments.sale, ...payments.debt]);
  }

  /// The payments that settle [sale] on the spot, linked to it: the server
  /// books every sale on the customer's account, so a sale not sold on
  /// credit needs its payments to leave the balance where it was.
  static List<Payment> settlingPayments(Sale sale) =>
      sale.settlement.toPayments(
        customerId: sale.customer.id,
        at: sale.date,
        idFor: (i) => _salePaymentId(sale.id, i),
        visitId: sale.visitId,
        saleId: sale.id,
      );

  static const _uuid = Uuid();

  /// Deterministic ids (uuid v5 in the URL namespace) keep a retried
  /// operation idempotent: `sale-payment/<saleId>/<i>` for the payments
  /// that settle a sale, `sale-debt-payment/<saleId>/<i>` for the debt paid
  /// with it and `sale-transaction/<saleId>/<method>` for the transaction
  /// uuid each payment method of that operation shares.
  static String _salePaymentId(String saleId, int index) =>
      _uuid.v5(Namespace.url.value, 'sale-payment/$saleId/$index');
}
