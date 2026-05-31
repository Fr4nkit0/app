import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/widgets/top_toast.dart';

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
        TopToast.showSuccess(context, 'Cliente guardado exitosamente');
        Navigator.of(context).pop();
      }
    });

    // Listen to errors and show snackbar
    ref.listen(customerFormProvider.select((state) => state.errorMessage), (
      prev,
      next,
    ) {
      if (next != null) {
        TopToast.showError(context, next);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nuevo Cliente'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D1B3E),
      ),
      body: SafeArea(
        child: Column(
          children: [
            CustomerStepIndicator(
              currentStep: formState.currentStep,
              isSubmitting: formState.isSubmitting,
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
            // Footer fijo con sombra
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
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
                    onPressed: formState.isCurrentStepValid &&
                            !formState.isSubmitting
                        ? (formState.currentStep == 2
                            ? formNotifier.submit
                            : formNotifier.nextStep)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
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
                            formState.currentStep == 2
                                ? 'Guardar Cliente'
                                : 'Siguiente',
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
