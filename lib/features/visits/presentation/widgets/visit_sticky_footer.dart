import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';

/// Presentational sticky footer for [VisitScreen].
class VisitStickyFooter extends StatelessWidget {
  const VisitStickyFooter({
    super.key,
    required this.isDone,
    required this.hasSales,
    required this.isSaleSelected,
    required this.hasSoloResult,
    required this.onBackToRoute,
    required this.onPrimaryPressed,
  });

  final bool isDone;
  final bool hasSales;
  final bool isSaleSelected;
  final bool hasSoloResult;
  final VoidCallback onBackToRoute;
  final VoidCallback? onPrimaryPressed;

  bool get _needsSoloResult =>
      !hasSales && !isSaleSelected && !hasSoloResult;

  String get _primaryLabel {
    if (hasSales) return 'Cerrar Visita';
    if (isSaleSelected) return 'Iniciar Registro de Venta';
    return 'Cerrar Visita';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final tokens = MarilinTokens.of(context);

    return Container(
      decoration: BoxDecoration(
        color: MarilinColors.surface,
        border: Border(top: BorderSide(color: MarilinColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
      child: isDone
          ? SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(onPressed: onBackToRoute, child: const Text('Volver a la Ruta')),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_needsSoloResult) ...[
                  Text(
                    'Seleccioná un resultado primero',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: MarilinColors.brandBlue,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    onPressed: _needsSoloResult ? null : onPrimaryPressed,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _primaryLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
