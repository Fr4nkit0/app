import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app/features/customers/domain/models/customer.preference.dart';

part 'customer_form_state.freezed.dart';

@freezed
abstract class CustomerFormState with _$CustomerFormState {
  const factory CustomerFormState({
    @Default(0) int currentStep,
    @Default('') String name,
    @Default('') String phone,
    @Default('') String street,
    @Default('') String apartment,
    @Default('') String floor,
    @Default('') String visualReference,
    @Default([]) List<CustomerPreference> preferences,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    String? errorMessage,
  }) = _CustomerFormState;

  const CustomerFormState._();

  bool get isIdentityValid => name.isNotEmpty;
  
  bool get isAddressValid => street.isNotEmpty;

  bool get isPreferenceValid => preferences.isNotEmpty;

  bool get isCurrentStepValid {
    switch (currentStep) {
      case 0:
        return isIdentityValid;
      case 1:
        return isAddressValid;
      case 2:
        return isPreferenceValid;
      default:
        return false;
    }
  }
}
