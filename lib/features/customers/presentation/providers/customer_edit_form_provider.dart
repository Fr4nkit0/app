import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/presentation/failure_message.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer_edit.dart';
import 'package:app/features/customers/presentation/providers/customer_usecase_providers.dart';

import 'customer_form_provider.dart';
import 'customer_form_state.dart';

/// The customer form over an existing [customer]: two steps (data and
/// address), prefilled, with the same field rules as a new customer.
/// Preferences do not sync and are not edited here.
class CustomerEditForm extends CustomerForm {
  CustomerEditForm(this.customer);

  final Customer customer;

  static const lastStep = 1;

  @override
  CustomerFormState build() {
    final address =
        customer.addresses.where((a) => a.isPrimary).firstOrNull ??
        customer.addresses.firstOrNull;
    return CustomerFormState(
      name: customer.name,
      phone: customer.phone ?? '',
      street: address?.street ?? '',
      neighborhood: address?.neighborhood ?? '',
      apartment: address?.apartment ?? '',
      floor: address?.floor ?? '',
      visualReference: address?.visualReference ?? '',
    );
  }

  @override
  Future<void> submit() async {
    if (!state.isIdentityValid || !state.isAddressValid) return;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    String? optional(String value) =>
        value.trim().isEmpty ? null : value.trim();
    try {
      await ref
          .read(editCustomerUseCaseProvider)
          .execute(
            CustomerEdit(
              customerId: customer.id,
              name: state.name.trim(),
              phone: optional(state.phone),
              street: optional(state.street),
              neighborhood: optional(state.neighborhood),
              apartment: optional(state.apartment),
              floor: optional(state.floor),
              visualReference: optional(state.visualReference),
            ),
          );
      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: failureMessage(
          e,
          fallback: 'No se guardaron los cambios. Reintentá.',
        ),
      );
    }
  }
}

final customerEditFormProvider = NotifierProvider.autoDispose
    .family<CustomerEditForm, CustomerFormState, Customer>(
      CustomerEditForm.new,
    );
