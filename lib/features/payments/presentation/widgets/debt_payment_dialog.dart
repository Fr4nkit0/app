import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/core/theme/sales_tokens.dart';

/// Result returned by [DebtPaymentDialog].
class DebtPaymentResult {
  final String method; // 'Efectivo' | 'Transferencia' | 'Mixto'
  final double? cashAmount;
  final double? transferAmount;

  const DebtPaymentResult({
    required this.method,
    this.cashAmount,
    this.transferAmount,
  });
}

/// Full-screen dialog to pay an existing debt.
///
/// Opens via [showDialog]:
/// ```dart
/// final result = await showDialog<DebtPaymentResult>(
///   context: context,
///   builder: (_) => DebtPaymentDialog(totalDebt: debtor.debtAmount),
/// );
/// ```
class DebtPaymentDialog extends StatefulWidget {
  final double totalDebt;

  const DebtPaymentDialog({super.key, required this.totalDebt});

  @override
  State<DebtPaymentDialog> createState() => _DebtPaymentDialogState();
}

class _DebtPaymentDialogState extends State<DebtPaymentDialog> {
  String? _selectedMethod;
  final _cashController = TextEditingController();
  final _transferController = TextEditingController();

  bool get _canConfirm {
    if (_selectedMethod == null) return false;
    final cash = double.tryParse(_cashController.text) ?? 0;
    final transfer = double.tryParse(_transferController.text) ?? 0;
    switch (_selectedMethod) {
      case 'Efectivo':
        return cash > 0 && cash <= widget.totalDebt + 0.01;
      case 'Transferencia':
        return transfer > 0 && transfer <= widget.totalDebt + 0.01;
      case 'Mixto':
        return (cash > 0 || transfer > 0) &&
            (cash + transfer) <= widget.totalDebt + 0.01;
      default:
        return false;
    }
  }

  double get _remaining {
    final cash = double.tryParse(_cashController.text) ?? 0;
    final transfer = double.tryParse(_transferController.text) ?? 0;
    switch (_selectedMethod) {
      case 'Efectivo':
        return widget.totalDebt - cash;
      case 'Transferencia':
        return widget.totalDebt - transfer;
      case 'Mixto':
        return widget.totalDebt - cash - transfer;
      default:
        return widget.totalDebt;
    }
  }

  void _onCashChanged(String value) => setState(() {});
  void _onTransferChanged(String value) => setState(() {});

  void _onMethodSelected(String label) {
    setState(() {
      if (label != _selectedMethod) {
        _cashController.clear();
        _transferController.clear();
        _selectedMethod = label;
      }
    });
  }

  Widget _buildRemainingIndicator() {
    final isCovered = _remaining.abs() <= 0.01;
    final isOverpaid = _remaining < -0.01;
    final primary = const Color(0xFF1565C0);

    if (isOverpaid) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Color(0xFFD32F2F),
            ),
            const SizedBox(width: 6),
            const Text(
              'Excede la deuda',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFFD32F2F),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Icon(
            isCovered ? Icons.check_circle_outline : Icons.info_outline,
            size: 16,
            color: isCovered ? primary : const Color(0xFFE65100),
          ),
          const SizedBox(width: 6),
          Text(
            isCovered
                ? '✓ Cubierto'
                : 'Restante: \$${_remaining.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isCovered ? primary : const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _transferController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<SalesTokens>() ?? SalesTokens.light;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Icon(Icons.payments_rounded, color: tokens.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Pagar deuda',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D1B3E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Deuda total: \$${widget.totalDebt.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 20),

            // ── Grid de métodos de pago ──
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPaymentOption(label: 'Efectivo', icon: '💵'),
                _buildPaymentOption(label: 'Transferencia', icon: '🏦'),
                _buildPaymentOption(label: 'Mixto', icon: '🔄'),
              ],
            ),

            // ── Campos de montos (según método) ──
            if (_selectedMethod != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                _selectedMethod == 'Mixto' ? 'MONTOS MIXTOS' : 'MONTO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              if (_selectedMethod == 'Efectivo')
                _AmountField(
                  label: 'Efectivo',
                  controller: _cashController,
                  onChanged: _onCashChanged,
                ),
              if (_selectedMethod == 'Transferencia')
                _AmountField(
                  label: 'Transferencia',
                  controller: _transferController,
                  onChanged: _onTransferChanged,
                ),
              if (_selectedMethod == 'Mixto') ...[
                _AmountField(
                  label: 'Efectivo',
                  controller: _cashController,
                  onChanged: _onCashChanged,
                ),
                const SizedBox(height: 10),
                _AmountField(
                  label: 'Transferencia',
                  controller: _transferController,
                  onChanged: _onTransferChanged,
                ),
              ],
              const SizedBox(height: 4),
              _buildRemainingIndicator(),
            ],

            const SizedBox(height: 24),

            // ── Botones Cancelar + Confirmar ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: SalesTokens.muted),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF0D1B3E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _canConfirm ? _confirm : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.primary,
                      disabledBackgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirmar pago',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({required String label, required String icon}) {
    final isSelected = _selectedMethod == label;
    final primary = const Color(0xFF1565C0);

    return GestureDetector(
      onTap: () => _onMethodSelected(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    final cash = double.tryParse(_cashController.text);
    final transfer = double.tryParse(_transferController.text);

    Navigator.of(context).pop(
      DebtPaymentResult(
        method: _selectedMethod!,
        cashAmount: cash,
        transferAmount: transfer,
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _AmountField({
    required this.label,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixText: '\$ ',
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
      ),
    );
  }
}
