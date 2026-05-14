import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/customer_form_provider.dart';
import '../widgets/step_identity_view.dart';
import '../widgets/step_address_view.dart';
import '../widgets/step_preference_view.dart';
import '../widgets/step_progress_indicator.dart';

class CreateCustomerScreen extends ConsumerStatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  ConsumerState<CreateCustomerScreen> createState() =>
      _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends ConsumerState<CreateCustomerScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(customerFormProvider);
    final formNotifier = ref.read(customerFormProvider.notifier);

    // Listen to step changes to animate page view
    ref.listen(customerFormProvider.select((state) => state.currentStep), (
      prev,
      next,
    ) {
      if (prev != next && _pageController.hasClients) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    // Listen to success and navigate
    ref.listen(customerFormProvider.select((state) => state.isSuccess), (
      prev,
      next,
    ) {
      if (next == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente guardado exitosamente')),
        );
        Navigator.of(context).pop();
      }
    });

    // Listen to errors and show snackbar
    ref.listen(customerFormProvider.select((state) => state.errorMessage), (
      prev,
      next,
    ) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Nuevo Cliente'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            CustomerStepIndicator(
              currentStep: formState.currentStep,
              isSubmitting: formState.isSubmitting,
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(
                    32,
                  ), // XL corners for M3 Expressive
                ),
                clipBehavior: Clip.antiAlias,
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Managed by buttons
                  children: [
                    StepIdentityView(
                      name: formState.name,
                      phone: formState.phone,
                      onNameChanged: formNotifier.updateName,
                      onPhoneChanged: formNotifier.updatePhone,
                    ),
                    StepAddressView(
                      street: formState.street,
                      apartment: formState.apartment,
                      floor: formState.floor,
                      visualReference: formState.visualReference,
                      onStreetChanged: formNotifier.updateStreet,
                      onApartmentChanged: formNotifier.updateApartment,
                      onFloorChanged: formNotifier.updateFloor,
                      onVisualReferenceChanged:
                          formNotifier.updateVisualReference,
                    ),
                    StepPreferenceView(
                      preferences: formState.preferences,
                      onAddPreference: formNotifier.addPreference,
                      onRemovePreference: formNotifier.removePreference,
                      onPreferenceChanged: formNotifier.updatePreference,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (formState.currentStep > 0)
                    TextButton(
                      onPressed: formState.isSubmitting
                          ? null
                          : formNotifier.previousStep,
                      child: const Text('Atrás'),
                    )
                  else
                    const SizedBox.shrink(),
                  FilledButton(
                    onPressed:
                        formState.isCurrentStepValid && !formState.isSubmitting
                        ? (formState.currentStep == 2
                              ? formNotifier.submit
                              : formNotifier.nextStep)
                        : null,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          100,
                        ), // Full rounded
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: formState.isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            formState.currentStep == 2
                                ? 'Guardar Cliente'
                                : 'Siguiente',
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
