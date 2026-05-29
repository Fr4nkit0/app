import 'package:flutter/material.dart';

class VisitActionButtons extends StatelessWidget {
  const VisitActionButtons({
    super.key,
    required this.onRegisterSale,
    required this.onMarkVisited,
    required this.onMarkAbsent,
  });

  final VoidCallback onRegisterSale;
  final VoidCallback onMarkVisited;
  final VoidCallback onMarkAbsent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onRegisterSale,
          icon: const Icon(Icons.point_of_sale_outlined),
          label: const Text('Registrar Venta'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFBF1B1B),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onMarkVisited,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Marcar Visitado'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
            foregroundColor: const Color(0xFF1565C0),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onMarkAbsent,
          icon: const Icon(Icons.person_off_outlined),
          label: const Text('Marcar Ausente'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}
