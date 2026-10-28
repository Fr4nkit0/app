import 'package:app/core/utils/resource.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/customers/data/repositories/customer_agreement.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer_agreement.repository.dart';
import 'package:app/features/customers/presentation/widgets/customer_agreements_tab.dart';
import 'package:app/features/products/presentation/providers/product_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showNewAgreementSheet(BuildContext context, String customerId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => NewAgreementSheet(customerId: customerId),
  );
}

/// Form to create a price agreement for [customerId] from the enabled
/// product catalog.
class NewAgreementSheet extends ConsumerStatefulWidget {
  const NewAgreementSheet({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<NewAgreementSheet> createState() => _NewAgreementSheetState();
}

class _NewAgreementSheetState extends ConsumerState<NewAgreementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _reason = TextEditingController();
  String? _productId;
  DateTime _validFrom = DateTime.now();
  DateTime? _validTo;
  bool _saving = false;

  @override
  void dispose() {
    _price.dispose();
    _reason.dispose();
    super.dispose();
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _show(DateTime d) => AgreementCard.formatDate(_iso(d));

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _validFrom = picked;
      if (_validTo != null && _day(_validTo!).isBefore(_day(picked))) {
        _validTo = null;
      }
    });
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validTo ?? _validFrom,
      firstDate: _validFrom,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _validTo = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await ref
        .read(driftCustomerAgreementRepositoryProvider)
        .create(
          customerId: widget.customerId,
          productId: _productId!,
          unitPrice: _parsePrice(_price.text)!,
          validFrom: _iso(_validFrom),
          validTo: _validTo == null ? null : _iso(_validTo!),
          reason: _reason.text,
        );
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop();
        TopToast.showSuccess(context, 'Acuerdo creado');
      case Error(:final error):
        setState(() => _saving = false);
        TopToast.showError(context, 'No se guardó el acuerdo. Reintentá.');
    }
  }

  static double? _parsePrice(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider).value ?? const [];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nuevo acuerdo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('agreement_product'),
                initialValue: _productId,
                decoration: const InputDecoration(labelText: 'Producto'),
                items: [
                  for (final p in products)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() => _productId = v),
                validator: (v) => v == null ? 'Elegí un producto' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('agreement_price'),
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio unitario',
                  prefixText: '\$ ',
                ),
                validator: (v) {
                  final value = _parsePrice(v ?? '');
                  if (value == null || value <= 0) {
                    return 'Ingresá un precio mayor a 0';
                  }
                  // The server keeps prices with two decimals and rejects more.
                  if (!RegExp(
                    r'^\d+([.,]\d{1,2})?$',
                  ).hasMatch((v ?? '').trim())) {
                    return 'Usá hasta 2 decimales';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vigente desde'),
                subtitle: Text(_show(_validFrom)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickFrom,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vigente hasta (opcional)'),
                subtitle: Text(
                  _validTo == null ? 'Sin fecha de fin' : _show(_validTo!),
                ),
                trailing: _validTo == null
                    ? const Icon(Icons.calendar_today_outlined)
                    : IconButton(
                        tooltip: 'Quitar',
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _validTo = null),
                      ),
                onTap: _pickTo,
              ),
              TextFormField(
                key: const Key('agreement_reason'),
                controller: _reason,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                ),
                validator: (v) =>
                    (v?.trim().length ?? 0) >
                        CustomerAgreementRepository.maxReasonLength
                    ? 'Máximo ${CustomerAgreementRepository.maxReasonLength} caracteres'
                    : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
