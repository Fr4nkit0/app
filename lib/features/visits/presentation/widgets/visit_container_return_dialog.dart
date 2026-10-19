import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/route/domain/models/route_stop.dart';

class StandaloneContainerReturnDialog extends ConsumerStatefulWidget {
  const StandaloneContainerReturnDialog({super.key, required this.stop});

  final RouteStop stop;

  @override
  ConsumerState<StandaloneContainerReturnDialog> createState() =>
      _StandaloneContainerReturnDialogState();
}

class _StandaloneContainerReturnDialogState
    extends ConsumerState<StandaloneContainerReturnDialog> {
  final Map<String, int> _returns = {'BIDON_20L': 0, 'SIFON_2L': 0};

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(
      customerContainerBalancesProvider(widget.stop.customer.id),
    );
    final balances = balancesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <CustomerContainerBalance>[],
    );

    return AlertDialog(
      title: const Text(
        'Registrar Retorno de Envases',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajustá la cantidad de envases vacíos que devuelve el cliente.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...['BIDON_20L', 'SIFON_2L'].map((type) {
              final returned = _returns[type] ?? 0;
              final label = type == 'BIDON_20L' ? 'Bidón 20L' : 'Sifón 2L';
              final balance = balances
                  .firstWhere(
                    (b) => b.containerType == type,
                    orElse: () => CustomerContainerBalance(
                      customerId: widget.stop.customer.id,
                      containerType: type,
                      quantity: 0,
                    ),
                  )
                  .quantity;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: returned > 0
                              ? () {
                                  setState(() {
                                    _returns[type] = returned - 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: MarilinColors.destructive,
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '$returned',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: returned < balance
                              ? () {
                                  setState(() {
                                    _returns[type] = returned + 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: MarilinColors.brandBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            final repository = ref.read(inventoryRepositoryProvider);
            for (final type in ['BIDON_20L', 'SIFON_2L']) {
              final returnedQty = _returns[type] ?? 0;
              final movement = ContainerMovement(
                id: const Uuid().v4(),
                customerId: widget.stop.customer.id,
                containerType: type,
                deliveredQuantity: 0,
                returnedQuantity: returnedQty,
                createdAt: DateTime.now(),
                visitId: widget.stop.id,
              );
              await repository.recordContainerMovement(movement);
            }

            ref.invalidate(visitMovementsProvider(widget.stop.id));

            if (context.mounted) {
              Navigator.of(context).pop();
              TopToast.show(
                context,
                message: 'Retorno de envases registrado',
                icon: Icons.check_circle_rounded,
                color: MarilinColors.success,
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: MarilinColors.brandBlue,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
