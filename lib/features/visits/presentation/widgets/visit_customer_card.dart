import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app/core/theme/marilin_tokens.dart';

class VisitCustomerCard extends StatelessWidget {
  const VisitCustomerCard({
    super.key,
    required this.customerName,
    required this.formattedAddress,
    this.phone,
    this.onMapPressed,
    this.onWhatsAppLongPress,
  });

  final String customerName;
  final String formattedAddress;
  final String? phone;
  final VoidCallback? onMapPressed;
  final VoidCallback? onWhatsAppLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MarilinColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MarilinColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: MarilinColors.brandNavy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'CLIENTE ACTUAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: MarilinColors.textMuted.withValues(alpha: 0.9),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      customerName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: MarilinColors.brandNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (onMapPressed != null) ...[
                const SizedBox(width: 12),
                Material(
                  color: MarilinColors.brandBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onMapPressed,
                    borderRadius: BorderRadius.circular(16),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.location_on,
                        color: MarilinColors.brandBlue,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: MarilinColors.border.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: MarilinColors.brandBlue.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 16,
                  color: MarilinColors.brandBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  formattedAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          if (phone != null && phone!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onLongPress: onWhatsAppLongPress,
                    child: Text(
                      phone!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
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
