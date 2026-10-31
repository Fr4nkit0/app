import 'package:flutter/material.dart';

import 'package:app/core/utils/money_formatter.dart';
import 'package:app/features/history/domain/models/customer_record.dart';
import 'package:app/features/history/presentation/widgets/history_date_utils.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/presentation/widgets/cancel_record_dialog.dart';
import 'package:app/features/visits/presentation/visit_outcome_display.dart';
import 'package:app/features/visits/presentation/widgets/visit_record_tile.dart';

/// The customer's records, newest first, shown like the visit REGISTRO.
class CustomerHistoryList extends StatelessWidget {
  const CustomerHistoryList({
    super.key,
    required this.records,
    required this.containerLabels,
    required this.now,
    required this.onCancelSale,
    required this.onCancelPayment,
  });

  final List<CustomerRecord> records;

  /// Short name of each container type by its catalog code.
  final Map<String, String> containerLabels;

  /// Decides which records can still be cancelled.
  final DateTime now;

  /// The driver asked to cancel the sale or payment with this id.
  final ValueChanged<String> onCancelSale;
  final ValueChanged<String> onCancelPayment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final record in records)
            VisitRecordTile(
              icon: _icon(record.type),
              title: _title(record.type),
              detail: [
                '${historySectionLabelForDate(record.date)} · '
                    '${formatClockTime(record.date)}',
                ..._details(record),
              ].join('\n'),
              amount: record.amount == null
                  ? null
                  : formatMoney(record.amount!),
              statusLabel: _statusLabel(record),
              action: record.isCancellableOn(now)
                  ? _cancelAction(record)
                  : null,
            ),
        ],
      ),
    );
  }

  /// Off-route sales and payments; a visit's are cancelled from the visit.
  Widget _cancelAction(CustomerRecord record) =>
      record.type == CustomerRecordType.payment
      ? CancelRecordAction(
          label: 'Anular cobro',
          onPressed: () => onCancelPayment(record.id),
        )
      : CancelRecordAction(
          label: 'Anular venta',
          onPressed: () => onCancelSale(record.id),
        );

  static String? _statusLabel(CustomerRecord record) {
    if (!record.isCancelled) return null;
    final isPayment = record.type == CustomerRecordType.payment;
    if (record.cancelledByAdmin) {
      return isPayment
          ? 'Anulado por el administrador'
          : 'Anulada por el administrador';
    }
    return isPayment ? 'Anulado' : 'Anulada';
  }

  static IconData _icon(CustomerRecordType type) => switch (type) {
    CustomerRecordType.visit => Icons.place_outlined,
    CustomerRecordType.sale => Icons.shopping_bag_outlined,
    CustomerRecordType.payment => Icons.payments_outlined,
    CustomerRecordType.containerMovement => Icons.inventory_2_outlined,
  };

  static String _title(CustomerRecordType type) => switch (type) {
    CustomerRecordType.visit => 'Visita',
    CustomerRecordType.sale => 'Venta',
    CustomerRecordType.payment => 'Cobro',
    CustomerRecordType.containerMovement => 'Envases',
  };

  List<String> _details(CustomerRecord record) => switch (record.type) {
    CustomerRecordType.visit => [?record.outcomeName, ?record.observations],
    CustomerRecordType.sale => [
      for (final item in record.saleItems)
        '${item.quantity} × ${item.productName}',
      ?record.saleMethod?.label,
    ],
    CustomerRecordType.payment => [
      switch (record.paymentType) {
        PaymentType.transfer => 'Transferencia',
        PaymentType.credit => 'Crédito',
        PaymentType.cash || null => 'Efectivo',
      },
      ?record.observations,
    ],
    CustomerRecordType.containerMovement => [
      [
        containerLabels[record.containerType] ?? record.containerType ?? '',
        if (record.deliveredQuantity > 0) 'Entregó ${record.deliveredQuantity}',
        if (record.returnedQuantity > 0) 'Devolvió ${record.returnedQuantity}',
      ].join(' · '),
    ],
  };
}
