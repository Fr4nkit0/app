import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/presentation/failure_message.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/inventory/domain/custody.dart';
import 'package:app/features/inventory/domain/models/container_exchange.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/inventory/presentation/providers/register_container_return_usecase_provider.dart';
import 'package:app/features/inventory/presentation/widgets/container_return_dialog.dart';

/// Records the containers a customer hands back without a sale, and the
/// skeletons lent without one, from the visit or the customer profile.
class RegisterContainerReturnDialog extends ConsumerWidget {
  const RegisterContainerReturnDialog({
    super.key,
    required this.customerId,
    this.visitId,
  });

  final String customerId;
  final String? visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containerTypes = ref
        .watch(containerTypesProvider)
        .maybeWhen(data: (types) => types, orElse: () => <ContainerType>[]);
    final balances = ref
        .watch(customerContainerBalancesProvider(customerId))
        .maybeWhen(
          data: (list) => list,
          orElse: () => <CustomerContainerBalance>[],
        );

    final lendsSkeleton = containerTypes.any(
      (t) => t.code == ContainerType.skeletonCode,
    );
    final truckSkeletons = lendsSkeleton
        ? ref.watch(truckSkeletonsProvider).value
        : null;

    return ContainerReturnDialog(
      containerTypes: containerTypes,
      custody: custodyByContainerType(balances),
      truckSkeletons: truckSkeletons,
      onConfirm: (exchange) => _save(context, ref, exchange),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    ContainerExchange exchange,
  ) async {
    final visitId = this.visitId;
    try {
      await ref
          .read(registerContainerReturnUseCaseProvider)
          .execute(
            customerId: customerId,
            visitId: visitId,
            returns: exchange.returns,
            deliveries: exchange.deliveries,
          );
    } catch (e) {
      // A failed return keeps the dialog open so the driver can retry.
      if (context.mounted) {
        TopToast.show(
          context,
          message: failureMessage(
            e,
            fallback: 'No se registró la devolución. Reintentá.',
          ),
          icon: Icons.error_outline,
          color: MarilinColors.destructive,
        );
      }
      return;
    }

    if (visitId != null) ref.invalidate(visitMovementsProvider(visitId));
    ref.invalidate(customerContainerBalancesProvider(customerId));

    if (context.mounted) {
      Navigator.of(context).pop();
      TopToast.show(
        context,
        message: 'Retorno de envases registrado',
        icon: Icons.check_circle_rounded,
        color: context.marilin.vivid(MarilinColors.success),
      );
    }
  }
}
