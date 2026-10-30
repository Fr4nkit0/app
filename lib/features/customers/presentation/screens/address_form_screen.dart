import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/presentation/failure_message.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/customers/domain/models/address_details.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/presentation/providers/customer_usecase_providers.dart';
import 'package:app/features/customers/presentation/widgets/step_address_view.dart';

/// Adds an address to [customerId], or edits [address] when given, with the
/// same fields as the new-customer wizard.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, required this.customerId, this.address});

  final String customerId;
  final CustomerAddress? address;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  late String _street = widget.address?.street ?? '';
  late String _neighborhood = widget.address?.neighborhood ?? '';
  late String _apartment = widget.address?.apartment ?? '';
  late String _floor = widget.address?.floor ?? '';
  late String _visualReference = widget.address?.visualReference ?? '';
  bool _submitting = false;

  bool get _isEdit => widget.address != null;

  bool get _isValid =>
      _street.trim().isNotEmpty && _neighborhood.trim().isNotEmpty;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final details = AddressDetails(
      street: _street,
      neighborhood: _neighborhood,
      apartment: _apartment,
      floor: _floor,
      visualReference: _visualReference,
    );
    try {
      final address = widget.address;
      if (address == null) {
        await ref
            .read(addAddressUseCaseProvider)
            .execute(customerId: widget.customerId, details: details);
      } else {
        await ref
            .read(editAddressUseCaseProvider)
            .execute(addressId: address.id, details: details);
      }
      if (!mounted) return;
      TopToast.showSuccess(
        context,
        _isEdit ? 'Dirección actualizada' : 'Dirección agregada',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      TopToast.showError(
        context,
        failureMessage(e, fallback: 'No se guardó la dirección. Reintentá.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.marilin.surface,
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar dirección' : 'Nueva dirección'),
        backgroundColor: context.marilin.surface,
        foregroundColor: context.marilin.ink,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StepAddressView(
                street: _street,
                neighborhood: _neighborhood,
                apartment: _apartment,
                floor: _floor,
                visualReference: _visualReference,
                onStreetChanged: (v) => setState(() => _street = v),
                onNeighborhoodChanged: (v) => setState(() => _neighborhood = v),
                onApartmentChanged: (v) => setState(() => _apartment = v),
                onFloorChanged: (v) => setState(() => _floor = v),
                onVisualReferenceChanged: (v) =>
                    setState(() => _visualReference = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: FilledButton(
                onPressed: _isValid && !_submitting ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: MarilinColors.brandBlue,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
