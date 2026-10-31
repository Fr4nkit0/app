import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/widgets/top_toast.dart';

import '../providers/customer_form_provider.dart';
import '../widgets/step_identity_view.dart';
import '../widgets/step_address_view.dart';
import '../widgets/step_preference_view.dart';
import '../widgets/discard_customer_dialog.dart';
import 'package:app/core/widgets/core_horizontal_stepper.dart';

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

    // Listen to step changes to jump page view
    ref.listen(customerFormProvider.select((state) => state.currentStep), (
      prev,
      next,
    ) {
      if (prev != next && _pageController.hasClients) {
        _pageController.jumpToPage(next);
      }
    });

    // Listen to success and navigate
    ref.listen(customerFormProvider.select((state) => state.isSuccess), (
      prev,
      next,
    ) {
      if (next == true) {
        TopToast.showSuccess(context, 'Cliente guardado exitosamente');
        // Returns the new customer so a sale started here can go on with it.
        Navigator.of(
          context,
        ).pop(ref.read(customerFormProvider).createdCustomer);
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

    final screen = Scaffold(
      backgroundColor: context.marilin.surface,
      appBar: AppBar(
        title: const Text('Nuevo Cliente'),
        backgroundColor: context.marilin.surface,
        foregroundColor: context.marilin.ink,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: CoreHorizontalStepper(
                steps: const ['Datos', 'Dirección', 'Preferencias'],
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
                      if (ref.read(customerFormProvider).isCurrentStepValid) {
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
                  StepPreferenceView(
                    preferences: formState.preferences,
                    onAddPreference: formNotifier.addPreference,
                    onRemovePreference: formNotifier.removePreference,
                    onPreferenceChanged: formNotifier.updatePreference,
                    onNewPreferenceSaved: (day, start, end) {
                      formNotifier.addPreference();
                      final newId = ref
                          .read(customerFormProvider)
                          .preferences
                          .last
                          .id;
                      formNotifier.updatePreference(
                        newId,
                        dayOfWeek: day,
                        timeWindowStart: start,
                        timeWindowEnd: end,
                      );
                    },
                  ),
                ],
              ),
            ),
            // Footer fijo con sombra
            Container(
              decoration: BoxDecoration(
                color: context.marilin.surface,
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
                    onPressed:
                        formState.isCurrentStepValid && !formState.isSubmitting
                        ? (formState.currentStep == 2
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

    return PopScope<Object?>(
      // Past the first step, back (system or app bar) goes back one step like
      // Atrás; on the first one it only drops typed data once confirmed.
      canPop:
          formState.isSuccess ||
          (formState.currentStep == 0 && !formState.hasEnteredData),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final current = ref.read(customerFormProvider);
        if (current.currentStep > 0) {
          if (!current.isSubmitting) formNotifier.previousStep();
          return;
        }
        final navigator = Navigator.of(context);
        if (await confirmDiscardCustomer(context)) navigator.pop();
      },
      child: screen,
    );
  }
}
