import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';

part 'customer_form_state.freezed.dart';

@freezed
abstract class CustomerFormState with _$CustomerFormState {
  const factory CustomerFormState({
    @Default(0) int currentStep,
    @Default('') String name,
    @Default('') String phone,
    @Default('') String street,
    @Default('') String neighborhood,
    @Default('') String apartment,
    @Default('') String floor,
    @Default('') String visualReference,
    @Default([]) List<CustomerPreference> preferences,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    /// The customer just saved, handed back to whoever opened the form.
    Customer? createdCustomer,
    String? errorMessage,
    double? latitude,
    double? longitude,
  }) = _CustomerFormState;

  const CustomerFormState._();

  /// Whether leaving now would throw away something the driver typed.
  bool get hasEnteredData => [
    name,
    phone,
    street,
    neighborhood,
    apartment,
    floor,
    visualReference,
  ].any((field) => field.trim().isNotEmpty);

  bool get isIdentityValid => name.isNotEmpty;

  bool get isAddressValid => street.isNotEmpty && neighborhood.isNotEmpty;

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
