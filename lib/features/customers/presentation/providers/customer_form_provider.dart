import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/presentation/failure_message.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/presentation/providers/customer_usecase_providers.dart';
import 'package:uuid/uuid.dart';

import 'customer_form_state.dart';

class CustomerForm extends Notifier<CustomerFormState> {
  @override
  CustomerFormState build() {
    return CustomerFormState(
      preferences: [
        CustomerPreference(
          id: const Uuid().v4(),
          dayOfWeek: 1, // Lunes
          timeWindowStart: '09:00',
          timeWindowEnd: '18:00',
        ),
      ],
    );
  }

  void nextStep() {
    if (state.isCurrentStepValid && state.currentStep < 2) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        errorMessage: null,
      );
    } else if (!state.isCurrentStepValid) {
      state = state.copyWith(
        errorMessage: 'Please fill in the required fields.',
      );
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        errorMessage: null,
      );
    }
  }

  void updateName(String name) {
    state = state.copyWith(name: name, errorMessage: null);
  }

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone, errorMessage: null);
  }

  void updateStreet(String street) {
    state = state.copyWith(street: street, errorMessage: null);
  }

  void updateNeighborhood(String neighborhood) {
    state = state.copyWith(neighborhood: neighborhood, errorMessage: null);
  }

  void updateApartment(String apartment) {
    state = state.copyWith(apartment: apartment);
  }

  void updateFloor(String floor) {
    state = state.copyWith(floor: floor);
  }

  void updateVisualReference(String visualReference) {
    state = state.copyWith(visualReference: visualReference);
  }

  void updateCoordinates(double? latitude, double? longitude) {
    state = state.copyWith(latitude: latitude, longitude: longitude);
  }

  void addPreference() {
    state = state.copyWith(
      preferences: [
        ...state.preferences,
        CustomerPreference(
          id: const Uuid().v4(),
          dayOfWeek: 1,
          timeWindowStart: '08:00',
          timeWindowEnd: '12:00',
        ),
      ],
      errorMessage: null,
    );
  }

  void removePreference(String id) {
    if (state.preferences.length <= 1) {
      state = state.copyWith(
        errorMessage: 'At least one preference is required.',
      );
      return;
    }
    state = state.copyWith(
      preferences: state.preferences.where((p) => p.id != id).toList(),
      errorMessage: null,
    );
  }

  void updatePreference(
    String id, {
    int? dayOfWeek,
    String? timeWindowStart,
    String? timeWindowEnd,
  }) {
    state = state.copyWith(
      preferences: [
        for (final p in state.preferences)
          if (p.id == id)
            p.copyWith(
              dayOfWeek: dayOfWeek ?? p.dayOfWeek,
              timeWindowStart: timeWindowStart ?? p.timeWindowStart,
              timeWindowEnd: timeWindowEnd ?? p.timeWindowEnd,
            )
          else
            p,
      ],
      errorMessage: null,
    );
  }

  /// Opens the optional opening balance section.
  void showOpeningBalance() {
    state = state.copyWith(isOpeningBalanceShown: true);
  }

  /// Folds the opening balance section and drops what was typed in it.
  void clearOpeningBalance() {
    state = state.copyWith(
      isOpeningBalanceShown: false,
      openingDebt: '',
      openingContainers: const {},
      errorMessage: null,
    );
  }

  void updateOpeningDebt(String debt) {
    state = state.copyWith(openingDebt: debt, errorMessage: null);
  }

  /// The containers of [containerType] the customer already holds.
  void updateOpeningContainers(String containerType, String count) {
    state = state.copyWith(
      openingContainers: {...state.openingContainers, containerType: count},
      errorMessage: null,
    );
  }

  Future<void> submit() async {
    if (state.currentStep != 2) return;
    if (!state.isOpeningBalanceValid) {
      state = state.copyWith(
        errorMessage:
            state.openingDebtError ?? state.openingContainerErrors.values.first,
      );
      return;
    }
    if (!state.isCurrentStepValid) return;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final customerId = const Uuid().v4();
      final addressId = const Uuid().v4();

      final customer = Customer(
        id: customerId,
        name: state.name,
        phone: state.phone.isEmpty ? null : state.phone,
        addresses: [
          CustomerAddress(
            id: addressId,
            street: state.street,
            neighborhood: state.neighborhood.isEmpty
                ? null
                : state.neighborhood,
            apartment: state.apartment.isEmpty ? null : state.apartment,
            floor: state.floor.isEmpty ? null : state.floor,
            visualReference: state.visualReference.isEmpty
                ? null
                : state.visualReference,
            latitude: state.latitude,
            longitude: state.longitude,
          ),
        ],
        preferences: state.preferences
            .map<CustomerPreference>((p) => p.copyWith())
            .toList(),
      );

      final stored = await ref
          .read(createCustomerUseCaseProvider)
          .execute(customer, opening: state.openingBalance);

      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        createdCustomer: stored,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: failureMessage(
          e,
          fallback: 'No se guardó el cliente. Reintentá.',
        ),
      );
    }
  }
}

final customerFormProvider =
    NotifierProvider.autoDispose<CustomerForm, CustomerFormState>(
      () => CustomerForm(),
    );
