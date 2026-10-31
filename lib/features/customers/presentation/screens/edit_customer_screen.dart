import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/widgets/core_horizontal_stepper.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/customers/domain/models/customer.dart';

import '../providers/customer_edit_form_provider.dart';
import '../widgets/step_address_view.dart';
import '../widgets/step_identity_view.dart';

/// Edits what syncs of an existing customer: data and one address, in the
/// same steps as the new-customer wizard.
class EditCustomerScreen extends ConsumerStatefulWidget {
  const EditCustomerScreen({super.key, required this.customer});

  final Customer customer;

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = customerEditFormProvider(widget.customer);
    final formState = ref.watch(provider);
    final formNotifier = ref.read(provider.notifier);
    final isLastStep = formState.currentStep == CustomerEditForm.lastStep;

    ref.listen(provider.select((state) => state.currentStep), (prev, next) {
      if (prev != next && _pageController.hasClients) {
        _pageController.jumpToPage(next);
      }
    });
    ref.listen(provider.select((state) => state.isSuccess), (prev, next) {
      if (next) {
        TopToast.showSuccess(context, 'Cliente actualizado');
        Navigator.of(context).pop();
      }
    });
    ref.listen(provider.select((state) => state.errorMessage), (prev, next) {
      if (next != null) TopToast.showError(context, next);
    });

    return Scaffold(
      backgroundColor: context.marilin.surface,
      appBar: AppBar(
        title: const Text('Editar cliente'),
        backgroundColor: context.marilin.surface,
        foregroundColor: context.marilin.ink,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: CoreHorizontalStepper(
                steps: const ['Datos', 'Dirección'],
                currentStep: formState.currentStep,
                isSubmitting: formState.isSubmitting,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StepIdentityView(
                    name: formState.name,
                    phone: formState.phone,
                    onNameChanged: formNotifier.updateName,
                    onPhoneChanged: formNotifier.updatePhone,
                    onPhoneSubmitted: () {
                      if (ref.read(provider).isCurrentStepValid) {
                        formNotifier.nextStep();
                      }
                    },
                  ),
                  StepAddressView(
                    street: formState.street,
                    neighborhood: formState.neighborhood,
                    apartment: formState.apartment,
                    floor: formState.floor,
                    visualReference: formState.visualReference,
                    onStreetChanged: formNotifier.updateStreet,
                    onNeighborhoodChanged: formNotifier.updateNeighborhood,
                    onApartmentChanged: formNotifier.updateApartment,
                    onFloorChanged: formNotifier.updateFloor,
                    onVisualReferenceChanged:
                        formNotifier.updateVisualReference,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (formState.currentStep > 0)
                    OutlinedButton(
                      onPressed: formState.isSubmitting
                          ? null
                          : formNotifier.previousStep,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(100, 52),
                      ),
                      child: const Text('Atrás'),
                    )
                  else
                    const SizedBox.shrink(),
                  FilledButton(
                    onPressed:
                        formState.isCurrentStepValid && !formState.isSubmitting
                        ? (isLastStep
                              ? formNotifier.submit
                              : formNotifier.nextStep)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: MarilinColors.brandBlue,
                      minimumSize: const Size(160, 52),
                    ),
                    child: formState.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isLastStep ? 'Guardar cambios' : 'Siguiente',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
