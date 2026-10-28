import 'package:app/core/utils/money_formatter.dart';
import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/payments/presentation/widgets/amount_field.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/presentation/widgets/payment_method_icon.dart';

/// Result returned by [DebtPaymentSheet].
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

/// Bottom sheet to pay an existing debt.
///
/// Opened by `registerDebtPayment` with [showModalBottomSheet].
class DebtPaymentSheet extends StatefulWidget {
  final double totalDebt;

  const DebtPaymentSheet({super.key, required this.totalDebt});

  @override
  State<DebtPaymentSheet> createState() => _DebtPaymentSheetState();
}

class _DebtPaymentSheetState extends State<DebtPaymentSheet> {
  String? _selectedMethod;
  final _cashController = TextEditingController();
  final _transferController = TextEditingController();

  bool get _canConfirm {
    if (_selectedMethod == null) return false;
    final cash = AmountField.parseAmount(_cashController.text) ?? 0;
    final transfer = AmountField.parseAmount(_transferController.text) ?? 0;
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

  bool get _canPayFull {
    switch (_selectedMethod) {
      case 'Efectivo':
      case 'Transferencia':
        return true;
      case 'Mixto':
        return _remaining.abs() <= 0.01;
      default:
        return false;
    }
  }

  double get _remaining {
    final cash = AmountField.parseAmount(_cashController.text) ?? 0;
    final transfer = AmountField.parseAmount(_transferController.text) ?? 0;
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
    final primary = MarilinColors.brandBlue;

    if (isOverpaid) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: MarilinColors.destructive,
            ),
            const SizedBox(width: 6),
            const Text(
              'Excede la deuda',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: MarilinColors.destructive,
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
            color: isCovered
                ? primary
                : context.marilin.vivid(MarilinColors.warning),
          ),
          const SizedBox(width: 6),
          Text(
            isCovered ? 'Cubierto' : 'Restante: ${formatMoney(_remaining)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isCovered
                  ? primary
                  : context.marilin.vivid(MarilinColors.warning),
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
    final primary = MarilinColors.brandBlue;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              'Deuda',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.marilin.textMuted,
              ),
            ),
            Text(
              formatMoney(widget.totalDebt),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: MarilinColors.destructive,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Forma de pago',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.marilin.ink,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentOption(
                    label: 'Efectivo',
                    method: PaymentMethod.cash,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPaymentOption(
                    label: 'Transferencia',
                    method: PaymentMethod.transfer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPaymentOption(
                    label: 'Mixto',
                    method: PaymentMethod.mixed,
                  ),
                ),
              ],
            ),
            if (_selectedMethod != null) ...[
              const SizedBox(height: 16),
              if (_selectedMethod == 'Efectivo')
                AmountField(
                  label: 'Efectivo',
                  controller: _cashController,
                  onChanged: _onCashChanged,
                ),
              if (_selectedMethod == 'Transferencia')
                AmountField(
                  label: 'Transferencia',
                  controller: _transferController,
                  onChanged: _onTransferChanged,
                ),
              if (_selectedMethod == 'Mixto') ...[
                AmountField(
                  label: 'Efectivo',
                  controller: _cashController,
                  onChanged: _onCashChanged,
                ),
                const SizedBox(height: 10),
                AmountField(
                  label: 'Transferencia',
                  controller: _transferController,
                  onChanged: _onTransferChanged,
                ),
              ],
              const SizedBox(height: 4),
              _buildRemainingIndicator(),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _canPayFull ? _payFull : null,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  disabledBackgroundColor: context.marilin.border,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Pagar deuda completa',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _canConfirm ? _confirm : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(
                    color: _canConfirm ? primary : context.marilin.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Registrar monto ingresado',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.marilin.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String label,
    required PaymentMethod method,
  }) {
    final isSelected = _selectedMethod == label;
    final primary = MarilinColors.brandBlue;
    final foreground = isSelected ? Colors.white : primary;
    final radius = BorderRadius.circular(14);

    return Material(
      key: ValueKey('method-card-$label'),
      color: isSelected ? primary : context.marilin.fill,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: isSelected ? primary : context.marilin.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: () => _onMethodSelected(label),
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(paymentMethodIcon(method), size: 22, color: foreground),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _payFull() {
    final method = _selectedMethod!;
    if (method == 'Mixto') return _confirm();
    Navigator.of(context).pop(
      DebtPaymentResult(
        method: method,
        cashAmount: method == 'Efectivo' ? widget.totalDebt : null,
        transferAmount: method == 'Transferencia' ? widget.totalDebt : null,
      ),
    );
  }

  void _confirm() {
    final cash = AmountField.parseAmount(_cashController.text);
    final transfer = AmountField.parseAmount(_transferController.text);

    Navigator.of(context).pop(
      DebtPaymentResult(
        method: _selectedMethod!,
        cashAmount: cash,
        transferAmount: transfer,
      ),
    );
  }
}
