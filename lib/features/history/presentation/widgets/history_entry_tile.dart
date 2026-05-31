import 'package:flutter/material.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';

class HistoryEntryTile extends StatelessWidget {
  const HistoryEntryTile({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    // Definimos estilo visual según el tipo de entrada de actividad
    final IconData iconData;
    final Color iconColor;
    final Color circleBgColor;
    final String typeTitle;
    final String timeStr = '${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}';

    switch (entry.type) {
      case HistoryEntryType.visit:
        iconData = Icons.local_shipping_rounded;
        iconColor = const Color(0xFF1565C0);
        circleBgColor = const Color(0xFFE3F2FD);
        typeTitle = 'Visita iniciada';
        break;
      case HistoryEntryType.sale:
        iconData = Icons.shopping_cart_rounded;
        iconColor = const Color(0xFF1565C0);
        circleBgColor = const Color(0xFFE3F2FD);
        typeTitle = 'Venta registrada';
        break;
      case HistoryEntryType.payment:
        iconData = Icons.payments_outlined;
        iconColor = const Color(0xFFBF1B1B);
        circleBgColor = const Color(0xFFFFEBEE);
        typeTitle = 'Cobro realizado';
        break;
      case HistoryEntryType.delivery:
        iconData = Icons.opacity_rounded;
        iconColor = const Color(0xFF1565C0);
        circleBgColor = const Color(0xFFE3F2FD);
        typeTitle = 'Entrega de bidones';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circular específico de la actividad
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: circleBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Columna de detalles textuales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            typeTitle,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0D1B3E),
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Nombre del cliente y monto formateado (si aplica)
                      Text(
                        entry.type == HistoryEntryType.payment && entry.amount != null
                            ? '${entry.customer.name} - \$${entry.amount!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'
                            : entry.customer.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      // Etiquetas/pills dinámicos (ej: 2 x 20L, MIXTO)
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: entry.tags.map((tag) {
                            final isMixto = tag.toLowerCase() == 'mixto';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isMixto
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isMixto
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFF1565C0),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Badge de sincronización nube/check
                Align(
                  alignment: Alignment.centerRight,
                  child: entry.isSynced
                      ? Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 13,
                          ),
                        )
                      : const Icon(
                          Icons.cloud_queue_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
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
