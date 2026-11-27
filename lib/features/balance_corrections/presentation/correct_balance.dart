import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/presentation/failure_message.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/balance_corrections/domain/models/balance_correction.dart';
import 'package:app/features/balance_corrections/presentation/providers/correct_balance_usecase_provider.dart';
import 'package:app/features/balance_corrections/presentation/widgets/balance_correction_sheet.dart';
import 'package:app/features/inventory/domain/custody.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';

/// Opens [BalanceCorrectionSheet] for [customerId] on [initialTarget]. A
/// saved correction closes it with a success toast; a failed one keeps it
/// open with the reason. The shown balances are watched streams, so they
/// follow the correction by themselves.
Future<void> correctBalance(
  BuildContext context, {
  required String customerId,
  BalanceTarget initialTarget = BalanceTarget.debt,
  String? initialContainerType,
  String? visitId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheetContext) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
    ),
    child: _BalanceCorrectionHost(
      customerId: customerId,
      initialTarget: initialTarget,
      initialContainerType: initialContainerType,
      visitId: visitId,
    ),
  ),
);

class _BalanceCorrectionHost extends ConsumerWidget {
  const _BalanceCorrectionHost({
    required this.customerId,
    required this.initialTarget,
    required this.initialContainerType,
    required this.visitId,
  });

  final String customerId;
  final BalanceTarget initialTarget;
  final String? initialContainerType;
  final String? visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debt = ref.watch(customerBalanceProvider(customerId)).value;
    final balances = ref
        .watch(customerContainerBalancesProvider(customerId))
        .value;
    final types = ref.watch(containerTypesProvider).value;
    // The sheet takes its initial target and debt side once: wait for
    // every value instead of opening on placeholders.
    if (debt == null || balances == null || types == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return BalanceCorrectionSheet(
      debt: debt,
      containerTypes: types,
      custody: custodyByContainerType(balances),
      initialTarget: initialTarget,
      initialContainerType: initialContainerType,
      onConfirm: (target, containerType, counted, reason) => _save(
        context,
        ref,
        target: target,
        containerType: containerType,
        counted: counted,
        reason: reason,
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    required BalanceTarget target,
    required String? containerType,
    required int counted,
    required String reason,
  }) async {
    try {
      await ref
          .read(correctBalanceUseCaseProvider)
          .execute(
            customerId: customerId,
            target: target,
            counted: counted,
            reason: reason,
            containerType: containerType,
            visitId: visitId,
          );
    } catch (e) {
      // A failed correction keeps the sheet open so the driver can retry.
      if (context.mounted) {
        TopToast.showError(
          context,
          failureMessage(e, fallback: 'No se guardó la corrección. Reintentá.'),
        );
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pop();
    TopToast.showSuccess(
      context,
      'Saldo corregido. Queda pendiente de revisión.',
    );
  }
}
