import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/presentation/failure_message.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/payments/domain/models/payment_split.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/payments/presentation/widgets/debt_payment_sheet.dart';

/// Opens [DebtPaymentSheet], registers the chosen split and reports the
/// outcome with a toast. Does nothing when the sheet is dismissed.
Future<void> registerDebtPayment(
  BuildContext context,
  WidgetRef ref, {
  required Customer customer,
  required double debt,
  String? visitId,
}) async {
  final split = await showModalBottomSheet<PaymentSplit>(
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
  if (split == null) return;

  try {
    await ref
        .read(registerDebtPaymentUseCaseProvider)
        .execute(customerId: customer.id, split: split, visitId: visitId);
  } catch (e) {
    if (!context.mounted) return;
    TopToast.show(
      context,
      message: failureMessage(e, fallback: 'No se guardó el pago. Reintentá.'),
      icon: Icons.error_outline,
      color: MarilinColors.destructive,
    );
    return;
  }
  if (!context.mounted) return;
  TopToast.show(
    context,
    message: 'Pago registrado con éxito',
    icon: Icons.check_circle_rounded,
    color: MarilinColors.success,
  );
}
