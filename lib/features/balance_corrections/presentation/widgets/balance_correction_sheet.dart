import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/money_formatter.dart';
import 'package:app/features/balance_corrections/domain/models/balance_correction.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/payments/presentation/widgets/amount_field.dart';

/// Called with what the driver corrects ([containerType] only for
/// containers), the real balance they counted (debt: negative is credit)
/// and the trimmed reason.
typedef BalanceCorrectionConfirm =
    FutureOr<void> Function(
      BalanceTarget target,
      String? containerType,
      num counted,
      String reason,
    );

/// Bottom sheet where the driver loads the REAL balance they counted for
/// the debt or one container type of a customer, with a required reason.
///
/// Presentational: the caller supplies the balances and saves on
/// [onConfirm]; the sheet stays open until the caller closes it.
class BalanceCorrectionSheet extends StatefulWidget {
  const BalanceCorrectionSheet({
    super.key,
    required this.debt,
    required this.containerTypes,
    required this.custody,
    required this.onConfirm,
    this.initialTarget = BalanceTarget.debt,
    this.initialContainerType,
  });

  static const countFieldKey = Key('balance-correction-count');
  static const reasonFieldKey = Key('balance-correction-reason');

  static const minReasonLength = 3;
  static const maxReasonLength = 500;

  /// The customer account the device shows (positive: the customer owes).
  final double debt;

  /// The catalog container types.
  final List<ContainerType> containerTypes;

  /// Containers the customer holds, by catalog code.
  final Map<String, int> custody;
  final BalanceCorrectionConfirm onConfirm;
  final BalanceTarget initialTarget;

  /// The container type selected on open when [initialTarget] is
  /// containers; the first offered type when null or unknown.
  final String? initialContainerType;

  @override
  State<BalanceCorrectionSheet> createState() => _BalanceCorrectionSheetState();
}

/// One thing the driver can correct, with the balance shown for it.
class _TargetOption {
  const _TargetOption.debt(this.current)
    : target = BalanceTarget.debt,
      code = null,
      label = 'Deuda';

  const _TargetOption.containers(this.code, this.label, this.current)
    : target = BalanceTarget.containers;

  final BalanceTarget target;
  final String? code;
  final String label;
  final num current;
}

class _BalanceCorrectionSheetState extends State<BalanceCorrectionSheet> {
  static final _wholeNumber = RegExp(r'^\d+$');

  final _countController = TextEditingController();
  final _reasonController = TextEditingController();
  late BalanceTarget _target;
  String? _containerType;
  late bool _credit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _credit = widget.debt < 0;
    final codes = _options.map((o) => o.code).whereType<String>().toList();
    if (widget.initialTarget == BalanceTarget.containers && codes.isNotEmpty) {
      _target = BalanceTarget.containers;
      _containerType = codes.contains(widget.initialContainerType)
          ? widget.initialContainerType
          : codes.first;
    } else {
      _target = BalanceTarget.debt;
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// The debt and every catalog type. A code the customer holds that the
  /// catalog no longer lists is left out: the server could never take its
  /// correction.
  List<_TargetOption> get _options => [
    _TargetOption.debt(widget.debt),
    for (final type in widget.containerTypes)
      _TargetOption.containers(
        type.code,
        type.label,
        widget.custody[type.code] ?? 0,
      ),
  ];

  bool _isSelected(_TargetOption option) =>
      option.target == _target && option.code == _containerType;

  num get _current => _target == BalanceTarget.debt
      ? widget.debt
      : widget.custody[_containerType] ?? 0;

  /// The counted balance typed so far; null while it does not parse.
  num? get _counted {
    final text = _countController.text.trim();
    switch (_target) {
      case BalanceTarget.containers:
        return _wholeNumber.hasMatch(text) ? int.parse(text) : null;
      case BalanceTarget.debt:
        final amount = AmountField.parseAmount(text);
        if (amount == null) return null;
        return _credit && amount != 0 ? -amount : amount;
    }
  }

  String get _reason => _reasonController.text.trim();

  bool get _canConfirm =>
      !_saving &&
      _counted != null &&
      _reason.length >= BalanceCorrectionSheet.minReasonLength &&
      _reason.length <= BalanceCorrectionSheet.maxReasonLength;

  String _format(num value) => _target == BalanceTarget.debt
      ? formatAccountBalance(value.toDouble())
      : '$value';

  void _select(_TargetOption option) {
    if (_isSelected(option)) return;
    setState(() {
      _target = option.target;
      _containerType = option.code;
      _countController.clear();
    });
  }

  Future<void> _confirm() async {
    final counted = _counted;
    if (counted == null || !_canConfirm) return;
    setState(() => _saving = true);
    try {
      await widget.onConfirm(
        _target,
        _target == BalanceTarget.containers ? _containerType : null,
        counted,
        _reason,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final counted = _counted;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.marilin.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Corregir saldo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.marilin.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cargá el saldo real que contaste, no la diferencia.',
              style: TextStyle(fontSize: 13, color: context.marilin.textMuted),
            ),
            const SizedBox(height: 20),
            _sectionLabel('¿Qué corregís?'),
            const SizedBox(height: 8),
            for (final option in _options) ...[
              _TargetTile(
                label: option.label,
                value: option.target == BalanceTarget.debt
                    ? formatAccountBalance(option.current.toDouble())
                    : '${option.current}',
                selected: _isSelected(option),
                onTap: _saving ? null : () => _select(option),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            _sectionLabel('Saldo real que contaste'),
            const SizedBox(height: 8),
            if (_target == BalanceTarget.debt) ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Debe')),
                  ButtonSegment(value: true, label: Text('Saldo a favor')),
                ],
                selected: {_credit},
                showSelectedIcon: false,
                onSelectionChanged: _saving
                    ? null
                    : (selection) => setState(() => _credit = selection.single),
              ),
              const SizedBox(height: 12),
              AmountField(
                key: BalanceCorrectionSheet.countFieldKey,
                label: 'Monto',
                controller: _countController,
                onChanged: (_) => setState(() {}),
              ),
            ] else
              _ContainerCountField(
                controller: _countController,
                onChanged: (_) => setState(() {}),
              ),
            if (counted != null) ...[
              const SizedBox(height: 10),
              Text(
                'Pasa de ${_format(_current)} a ${_format(counted)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.marilin.ink,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _sectionLabel('Motivo'),
            const SizedBox(height: 8),
            TextField(
              key: BalanceCorrectionSheet.reasonFieldKey,
              controller: _reasonController,
              onChanged: (_) => setState(() {}),
              minLines: 2,
              maxLines: 4,
              maxLength: BalanceCorrectionSheet.maxReasonLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                context,
                hintText: 'Ej.: el cliente devolvió 2 bidones sin registrar',
                helperText:
                    'Obligatorio, al menos '
                    '${BalanceCorrectionSheet.minReasonLength} caracteres.',
              ),
            ),
            const SizedBox(height: 8),
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
                    'Se aplica ahora y la oficina la revisa.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.marilin.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canConfirm ? _confirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: MarilinColors.brandBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text(
                'Guardar corrección',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: context.marilin.ink,
    ),
  );
}

InputDecoration _inputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  String? helperText,
  String? errorText,
}) => InputDecoration(
  labelText: labelText,
  hintText: hintText,
  helperText: helperText,
  errorText: errorText,
  filled: true,
  fillColor: context.marilin.fill,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: context.marilin.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: context.marilin.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: MarilinColors.brandBlue, width: 1.5),
  ),
);

/// Whole container count; flags anything with decimals instead of
/// silently dropping the separator.
class _ContainerCountField extends StatelessWidget {
  const _ContainerCountField({
    required this.controller,
    required this.onChanged,
  });

  static final _wholeNumber = RegExp(r'^\d+$');

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = controller.text.trim();
    final invalid = text.isNotEmpty && !_wholeNumber.hasMatch(text);
    return TextField(
      key: BalanceCorrectionSheet.countFieldKey,
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: _inputDecoration(
        context,
        labelText: 'Envases',
        errorText: invalid ? 'Ingresá un número entero, sin decimales.' : null,
      ),
    );
  }
}

/// A selectable row: what can be corrected and its current balance.
class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? MarilinColors.brandBlue : context.marilin.border;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? context.marilin.soft(
                MarilinColors.brandBlue.withValues(alpha: 0.08),
              )
            : context.marilin.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: selected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected
                      ? MarilinColors.brandBlue
                      : context.marilin.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.marilin.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.marilin.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
