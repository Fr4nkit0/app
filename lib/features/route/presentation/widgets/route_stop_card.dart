import 'package:flutter/material.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/domain/models/visit_type.dart';

class RouteStopCard extends StatelessWidget {
  const RouteStopCard({
    super.key,
    required this.stop,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final RouteStop stop;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  Color _getPastelColor(String name) {
    final hash = name.hashCode;
    final colors = [
      const Color(0xFFE0F2FE), // Blue
      const Color(0xFFFCE7F3), // Pink
      const Color(0xFFFEF3C7), // Amber
      const Color(0xFFE8F5E9), // Green
      const Color(0xFFF3E8FF), // Purple
      const Color(0xFFFFEDD5), // Orange
    ];
    return colors[hash.abs() % colors.length];
  }

  Color _getTextColor(String name) {
    final hash = name.hashCode;
    final colors = [
      const Color(0xFF0369A1),
      const Color(0xFFBE185D),
      const Color(0xFFB45309),
      const Color(0xFF2E7D32),
      const Color(0xFF6B21A8),
      const Color(0xFFC2410C),
    ];
    return colors[hash.abs() % colors.length];
  }

  String _getInitials(String name) {
    final cleanName = name.replaceAll(RegExp(r"[^\w\s]"), '').trim();
    final parts = cleanName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final isDone = stop.status == StopStatus.done;
    final isAbsent = stop.status == StopStatus.absent;

    // Timeline color coding
    final Color timelineColor = isDone
        ? const Color(0xFF10B981) // Green
        : isAbsent
            ? const Color(0xFFEF4444) // Red
            : const Color(0xFFD1D5DB); // Gray

    final initials = _getInitials(stop.customer.name);
    final avatarBg = _getPastelColor(stop.customer.name);
    final avatarText = _getTextColor(stop.customer.name);

    return Stack(
      children: [
        // Gapless timeline connector line
        Positioned(
          left: 32,
          top: isFirst ? 28 : 0,
          bottom: isLast ? 28 : 0,
          child: Container(
            width: 2.5,
            color: timelineColor.withValues(alpha: 0.4),
          ),
        ),
        // Stop row content
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Timeline Status Indicator
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF10B981)
                          : isAbsent
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF1565C0),
                      width: 2.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Color(0xFF10B981))
                      : isAbsent
                          ? const Icon(Icons.close_rounded,
                              size: 16, color: Color(0xFFEF4444))
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1565C0),
                                shape: BoxShape.circle,
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. The Stop Card itself
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFFE8F5E9)
                          : isAbsent
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFF3F4F6),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top line: Name + Scheduled Time
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Pastel Avatar
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isDone || isAbsent
                                          ? Colors.grey.shade100
                                          : avatarBg,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        color: isDone || isAbsent
                                            ? Colors.grey.shade400
                                            : avatarText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stop.customer.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDone || isAbsent
                                                ? Colors.grey.shade400
                                                : const Color(0xFF0D1B3E),
                                            decoration: isDone
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          stop.customer.addresses.isNotEmpty
                                              ? stop.customer.addresses.first
                                                      .street ??
                                                  ''
                                              : 'Sin dirección',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Time bubble
                                  _buildTimeBubble(stop.scheduledAt,
                                      isDone: isDone, isAbsent: isAbsent),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Bottom line: Tags + Actions
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Chips / Badges
                                  Expanded(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (stop.customer.debtAmount > 0)
                                          _buildDebtChip(
                                              stop.customer.debtAmount),
                                        if (stop.customer.productLabels
                                            .isNotEmpty)
                                          _buildProductChip(stop
                                              .customer.productLabels.first),
                                      ],
                                    ),
                                  ),
                                  // Mini Quick Actions
                                  Row(
                                    children: [
                                      _buildQuickActionButton(
                                        icon: Icons.phone_in_talk_outlined,
                                        onTap: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Llamando a ${stop.customer.name}...'),
                                              duration:
                                                  const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      _buildQuickActionButton(
                                        icon: Icons.map_outlined,
                                        onTap: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Abriendo mapa para ${stop.customer.addresses.first.street ?? ''}...'),
                                              duration:
                                                  const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBubble(DateTime time,
      {required bool isDone, required bool isAbsent}) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');

    final color = isDone
        ? Colors.grey.shade400
        : isAbsent
            ? Colors.red.shade300
            : const Color(0xFF1565C0);
    final bg = isDone
        ? Colors.grey.shade100
        : isAbsent
            ? const Color(0xFFFFEBEE)
            : const Color(0xFF1565C0).withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$h:$m',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTypeChip(VisitType type) {
    final isSale = type == VisitType.sale;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSale
            ? const Color(0xFF1565C0).withValues(alpha: 0.08)
            : const Color(0xFF9E9E9E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isSale ? 'Venta' : 'Visita',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSale ? const Color(0xFF1565C0) : const Color(0xFF616161),
        ),
      ),
    );
  }

  Widget _buildDebtChip(double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 11, color: Color(0xFFEF4444)),
          const SizedBox(width: 3),
          Text(
            'Deuda: \$${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0369A1).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.water_drop_outlined,
              size: 11, color: Color(0xFF0369A1)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0369A1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}
