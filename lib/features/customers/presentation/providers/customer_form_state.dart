import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/domain/models/opening_balance.dart';
import 'package:app/features/payments/presentation/widgets/amount_field.dart';

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

    /// Whether the driver opened the optional opening balance section.
    @Default(false) bool isOpeningBalanceShown,

    /// The opening debt as typed; empty means none.
    @Default('') String openingDebt,

    /// The containers on loan as typed, by catalog code; empty means none.
    @Default({}) Map<String, String> openingContainers,
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

  static const invalidOpeningDebt = 'Ingresá un monto mayor o igual a cero.';
  static const invalidOpeningContainers =
      'Ingresá un número entero mayor o igual a cero.';
  static final _wholeNumber = RegExp(r'^\d+$');

  /// Why the typed opening debt cannot be saved; null when it can.
  String? get openingDebtError {
    final text = openingDebt.trim();
    if (text.isEmpty || AmountField.parseAmount(text) != null) return null;
    return invalidOpeningDebt;
  }

  /// Why each typed container count cannot be saved, by catalog code.
  Map<String, String> get openingContainerErrors => {
    for (final MapEntry(key: code, value: text) in openingContainers.entries)
      if (text.trim().isNotEmpty && !_wholeNumber.hasMatch(text.trim()))
        code: invalidOpeningContainers,
  };

  bool get isOpeningBalanceValid =>
      openingDebtError == null && openingContainerErrors.isEmpty;

  /// The typed opening balance; blanks count as zero. Only meaningful
  /// while [isOpeningBalanceValid].
  OpeningBalance get openingBalance => OpeningBalance(
    debt: AmountField.parseAmount(openingDebt) ?? 0,
    containers: {
      for (final MapEntry(key: code, value: text) in openingContainers.entries)
        if (_wholeNumber.hasMatch(text.trim())) code: int.parse(text.trim()),
    },
  );

  bool get isIdentityValid => name.isNotEmpty;

  /// The neighborhood is optional: not every customer has one.
  bool get isAddressValid => street.isNotEmpty;

  bool get isPreferenceValid => preferences.isNotEmpty;

  bool get isCurrentStepValid {
    switch (currentStep) {
      case 0:
        return isIdentityValid;
      case 1:
        return isAddressValid;
      case 2:
        return isPreferenceValid && isOpeningBalanceValid;
      default:
        return false;
    }
  }
}
