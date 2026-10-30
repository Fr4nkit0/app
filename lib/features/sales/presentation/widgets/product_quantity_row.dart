import 'package:app/core/utils/money_formatter.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/core/theme/sales_tokens.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/core/theme/marilin_tokens.dart';

/// Pure presentational widget for a product row with quantity stepper.
/// Has zero Riverpod dependency — all state and actions come from the parent.
class ProductQuantityRow extends StatelessWidget {
  const ProductQuantityRow({
    super.key,
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.onQuantitySubmitted,
  });

  final Product product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  /// Receives a validated quantity (0-999) typed in the numeric entry dialog.
  /// When null, tapping the quantity does nothing.
  final ValueChanged<int>? onQuantitySubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final cs = Theme.of(context).colorScheme;
    final hasQuantity = quantity > 0;
    final primary = tokens.primary;
    final available = product.available;
    // Selling over the truck stock is allowed (the truck may carry more than
    // the app knows); the driver is only warned.
    final overStock = available != null && quantity > available;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: hasQuantity
            ? primary.withValues(alpha: 0.05)
            : context.marilin.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasQuantity
              ? primary.withValues(alpha: 0.4)
              : context.marilin.border,
          width: hasQuantity ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasQuantity
                ? primary.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: hasQuantity ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icono del producto
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasQuantity
                      ? primary.withValues(alpha: 0.12)
                      : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  size: 22,
                  color: hasQuantity ? primary : cs.outline,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: hasQuantity ? primary : context.marilin.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      !product.hasPrice
                          ? 'Sin precio · no se puede vender'
                          : product.agreementId == null
                          ? '${formatMoney(product.price)} c/u'
                          : '${formatMoney(product.price)} c/u · acuerdo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasQuantity
                            ? primary.withValues(alpha: 0.8)
                            : cs.outline,
                        fontFeatures: tokens.tabularStyle.fontFeatures,
                      ),
                    ),
                    if (overStock) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Solo quedan ${available < 0 ? 0 : available} en el camión',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Stepper
              _QuantityStepper(
                quantity: quantity,
                primary: primary,
                cs: cs,
                onDecrement: quantity > 0 ? onDecrement : null,
                onIncrement: product.hasPrice ? onIncrement : null,
                onQuantitySubmitted: onQuantitySubmitted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.primary,
    required this.cs,
    required this.onDecrement,
    required this.onIncrement,
    required this.onQuantitySubmitted,
  });

  final int quantity;
  final Color primary;
  final ColorScheme cs;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final ValueChanged<int>? onQuantitySubmitted;

  Future<void> _askQuantity(BuildContext context) async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) => _QuantityDialog(initial: quantity),
    );
    if (value != null) onQuantitySubmitted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final submit = onQuantitySubmitted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon: Icons.remove_rounded,
          onTap: onDecrement,
          active: quantity > 0,
          primary: context.marilin.vivid(MarilinColors.destructive),
          cs: cs,
        ),
        InkWell(
          onTap: submit == null ? null : () => _askQuantity(context),
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: quantity > 0 ? primary : SalesTokens.muted,
                ),
              ),
            ),
          ),
        ),
        _Btn(
          icon: Icons.add_rounded,
          onTap: onIncrement,
          active: onIncrement != null,
          primary: primary,
          cs: cs,
        ),
      ],
    );
  }
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.initial});

  final int initial;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  static const _max = 999;

  late final TextEditingController _controller = TextEditingController(
    text: '${widget.initial}',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _accept() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 0 || value > _max) {
      setState(() => _error = 'Ingresá un número entre 0 y $_max');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cantidad'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(errorText: _error),
        onSubmitted: (_) => _accept(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _accept, child: const Text('Aceptar')),
      ],
    );
  }
}

/// Stepper button: a tap fires once; holding fires repeatedly.
class _Btn extends StatefulWidget {
  const _Btn({
    required this.icon,
    required this.onTap,
    required this.active,
    required this.primary,
    required this.cs,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final Color primary;
  final ColorScheme cs;

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  static const _holdDelay = Duration(milliseconds: 400);
  static const _repeatInterval = Duration(milliseconds: 150);

  Timer? _delay;
  Timer? _repeat;
  bool _repeated = false;

  void _startHold() {
    _repeated = false;
    _stopHold();
    _delay = Timer(_holdDelay, () {
      _repeated = true;
      _fire();
      _repeat = Timer.periodic(_repeatInterval, (_) => _fire());
    });
  }

  void _fire() {
    final onTap = widget.onTap;
    if (onTap == null) {
      _stopHold();
      return;
    }
    onTap();
  }

  void _stopHold() {
    _delay?.cancel();
    _repeat?.cancel();
    _delay = null;
    _repeat = null;
  }

  void _handleTap() {
    // The hold already fired the action; the release must not add one more.
    if (_repeated) {
      _repeated = false;
      return;
    }
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _stopHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.active && widget.onTap != null;
    final primary = widget.primary;
    return Listener(
      onPointerDown: (_) {
        if (isEnabled) _startHold();
      },
      onPointerUp: (_) => _stopHold(),
      onPointerCancel: (_) => _stopHold(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap == null ? null : _handleTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            width: 56,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isEnabled ? 0.1 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: 24,
                color: isEnabled ? primary : primary.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
