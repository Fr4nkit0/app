import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/inventory/domain/custody.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/inventory/presentation/providers/register_container_return_usecase_provider.dart';
import 'package:app/features/inventory/presentation/widgets/container_return_dialog.dart';

/// Records the containers a customer hands back without a sale, from the
/// visit or the customer profile.
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

    return ContainerReturnDialog(
      containerTypes: containerTypes,
      custody: custodyByContainerType(balances),
      onConfirm: (returns) => _save(context, ref, returns),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    Map<String, int> returns,
  ) async {
    final visitId = this.visitId;
    final result = await ref
        .read(registerContainerReturnUseCaseProvider)
        .execute(customerId: customerId, visitId: visitId, returns: returns);
    // A failed return keeps the dialog open so the driver can retry.
    if (result is Error<void>) return;

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
