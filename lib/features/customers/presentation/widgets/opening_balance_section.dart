import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/payments/presentation/widgets/amount_field.dart';

/// Optional part of the new-customer wizard where the driver loads what
/// the customer already owes and the containers they already hold, so the
/// account starts right instead of being corrected afterwards.
///
/// Presentational: folded until [onShow]; the caller keeps the typed
/// values and validates them.
class OpeningBalanceSection extends StatefulWidget {
  const OpeningBalanceSection({
    super.key,
    required this.isShown,
    required this.debt,
    required this.containers,
    required this.containerTypes,
    required this.containerErrors,
    required this.onShow,
    required this.onRemove,
    required this.onDebtChanged,
    required this.onContainersChanged,
  });

  static const debtFieldKey = Key('opening-balance-debt');
  static Key containersFieldKey(String code) =>
      ValueKey('opening-balance-containers-$code');

  final bool isShown;

  /// The opening debt as typed.
  final String debt;

  /// The containers on loan as typed, by catalog code.
  final Map<String, String> containers;

  /// The catalog container types; null while they load.
  final List<ContainerType>? containerTypes;

  /// Why a typed count cannot be saved, by catalog code.
  final Map<String, String> containerErrors;
  final VoidCallback onShow;

  /// Folds the section; the caller drops the typed values.
  final VoidCallback onRemove;
  final ValueChanged<String> onDebtChanged;
  final void Function(String containerType, String count) onContainersChanged;

  @override
  State<OpeningBalanceSection> createState() => _OpeningBalanceSectionState();
}

class _OpeningBalanceSectionState extends State<OpeningBalanceSection> {
  late final _debtController = TextEditingController(text: widget.debt);
  final _containerControllers = <String, TextEditingController>{};

  TextEditingController _containerController(String code) =>
      _containerControllers.putIfAbsent(
        code,
        () => TextEditingController(text: widget.containers[code] ?? ''),
      );

  @override
  void didUpdateWidget(OpeningBalanceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follows the values the caller holds, e.g. cleared by onRemove.
    if (_debtController.text != widget.debt) _debtController.text = widget.debt;
    for (final MapEntry(key: code, value: controller)
        in _containerControllers.entries) {
      final value = widget.containers[code] ?? '';
      if (controller.text != value) controller.text = value;
    }
  }

  @override
  void dispose() {
    _debtController.dispose();
    for (final controller in _containerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types = widget.containerTypes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.marilin.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.marilin.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: MarilinColors.brandBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo inicial (opcional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.marilin.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '¿Ya debe plata o tiene envases en comodato?',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.marilin.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isShown)
                TextButton(
                  onPressed: widget.onRemove,
                  child: const Text('Quitar'),
                ),
            ],
          ),
          if (!widget.isShown) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onShow,
              icon: const Icon(Icons.add),
              label: const Text('Cargar saldo inicial'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            AmountField(
              key: OpeningBalanceSection.debtFieldKey,
              label: 'Deuda inicial',
              controller: _debtController,
              onChanged: widget.onDebtChanged,
            ),
            const SizedBox(height: 16),
            Text(
              'Comodatos activos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.marilin.ink,
              ),
            ),
            const SizedBox(height: 8),
            if (types == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (types.isEmpty)
              Text(
                'No hay tipos de envase cargados.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.marilin.textMuted,
                ),
              )
            else
              for (final type in types) ...[
                _ContainerCountField(
                  key: OpeningBalanceSection.containersFieldKey(type.code),
                  label: type.label,
                  controller: _containerController(type.code),
                  errorText: widget.containerErrors[type.code],
                  onChanged: (count) =>
                      widget.onContainersChanged(type.code, count),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: context.marilin.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Se cargan como corrección de saldo y la oficina las '
                    'revisa.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.marilin.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Whole container count; lets a separator through so a fraction is
/// flagged instead of silently dropped.
class _ContainerCountField extends StatelessWidget {
  const _ContainerCountField({
    super.key,
    required this.label,
    required this.controller,
    required this.errorText,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: context.marilin.border),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        errorText: errorText,
        filled: true,
        fillColor: context.marilin.fill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: MarilinColors.brandBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
