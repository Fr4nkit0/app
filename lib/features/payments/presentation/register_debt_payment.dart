import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/payments/presentation/widgets/debt_payment_sheet.dart';

/// Opens [DebtPaymentSheet], records the chosen payments and reports the
/// outcome with a toast. Does nothing when the sheet is dismissed.
Future<void> registerDebtPayment(
  BuildContext context,
  WidgetRef ref, {
  required Customer customer,
  required double debt,
  String? visitId,
}) async {
  final result = await showModalBottomSheet<DebtPaymentResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: DebtPaymentSheet(totalDebt: debt),
    ),
  );
  if (result == null) return;

  final now = DateTime.now();
  Payment build(double amount, PaymentType type, DateTime createdAt) => Payment(
    id: const Uuid().v4(),
    customerId: customer.id,
    amount: amount,
    type: type,
    createdAt: createdAt,
    visitId: visitId,
  );

  final cash = result.cashAmount;
  final transfer = result.transferAmount;
  final payments = <Payment>[];
  switch (result.method) {
    case 'Efectivo':
      payments.add(build(cash!, PaymentType.cash, now));
    case 'Transferencia':
      payments.add(build(transfer!, PaymentType.transfer, now));
    case 'Mixto':
      if (cash != null && cash > 0) {
        payments.add(build(cash, PaymentType.cash, now));
      }
      if (transfer != null && transfer > 0) {
        payments.add(
          build(
            transfer,
            PaymentType.transfer,
            now.add(const Duration(milliseconds: 10)),
          ),
        );
      }
  }
  if (payments.isEmpty) return;

  final res = await ref.read(registerPaymentUseCaseProvider).execute(payments);
  if (!context.mounted) return;
  switch (res) {
    case Success():
      TopToast.show(
        context,
        message: 'Pago registrado con éxito',
        icon: Icons.check_circle_rounded,
        color: MarilinColors.success,
      );
    case Error():
      TopToast.show(
        context,
        message: 'No se guardó el pago. Reintentá.',
        icon: Icons.error_outline,
        color: MarilinColors.destructive,
      );
  }
}
