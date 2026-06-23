import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/domain/usecases/create.customer.usecase.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';
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

  Future<void> submit() async {
    if (!state.isCurrentStepValid || state.currentStep != 2) return;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final repository = ref.read(customerRepositoryProvider);
      final useCase = CreateCustomerUseCase(customerRepository: repository);

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

      final result = await useCase.execute(customer);

      switch (result) {
        case Success():
          state = state.copyWith(isSubmitting: false, isSuccess: true);
        case Error(:final error):
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: error.toString(),
          );
      }
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }
}

final customerFormProvider =
    NotifierProvider.autoDispose<CustomerForm, CustomerFormState>(
      () => CustomerForm(),
    );
