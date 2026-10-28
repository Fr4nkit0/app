import 'package:app/core/utils/money_formatter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/address_formatter.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/core/widgets/top_toast.dart';

BoxDecoration _heroDecoration(BuildContext context) => BoxDecoration(
  color: context.marilin.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: context.marilin.border, width: 1.5),
);

/// Hero card for the stop the driver should visit next.
class NextStopCard extends StatelessWidget {
  const NextStopCard({
    super.key,
    required this.stop,
    required this.custodyCount,
    required this.onTap,
  });

  final RouteStop stop;

  /// Containers at the customer's location; the item is hidden at 0.
  final int custodyCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final customer = stop.customer;
    final phone = customer.phone?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
    final hasPhone = (customer.phone ?? '').isNotEmpty;
    final address = customer.addresses.isEmpty
        ? null
        : customer.addresses.first;
    final time = stop.scheduledAt;
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: _heroDecoration(context),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Próxima parada',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.marilin.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  customer.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: context.marilin.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address == null
                      ? 'Sin dirección cargada'
                      : AddressFormatter.format(
                          street: address.street,
                          neighborhood: address.neighborhood,
                          floor: address.floor,
                          apartment: address.apartment,
                          visualReference: address.visualReference,
                        ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.marilin.inkSecondary,
                  ),
                ),
                if (stop.hasScheduledTime) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Programada $timeLabel',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.marilin.inkSecondary,
                    ),
                  ),
                ],
                if (customer.debtAmount > 0 || custodyCount > 0) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (customer.debtAmount > 0)
                        Text(
                          'Debe ${formatMoney(customer.debtAmount)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.marilin.destructive,
                          ),
                        ),
                      if (custodyCount > 0)
                        Text(
                          '$custodyCount envases en custodia',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.marilin.inkSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
                if (hasPhone) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.call_rounded,
                          label: 'Llamar',
                          uri: Uri.parse('tel:$phone'),
                          failureMessage: 'No se pudo abrir el teléfono',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.chat_rounded,
                          label: 'WhatsApp',
                          uri: Uri.parse('https://wa.me/$phone'),
                          failureMessage: 'No se pudo abrir WhatsApp',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.uri,
    required this.failureMessage,
  });

  final IconData icon;
  final String label;
  final Uri uri;
  final String failureMessage;

  Future<void> _launch(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      TopToast.showError(context, failureMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _launch(context),
      icon: Icon(icon, size: 20),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

/// Replaces the hero when every stop of the day is closed.
class RouteDoneCard extends StatelessWidget {
  const RouteDoneCard({super.key, required this.closedCount});

  final int closedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _heroDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ruta terminada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: context.marilin.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$closedCount paradas cerradas',
            style: TextStyle(fontSize: 14, color: context.marilin.inkSecondary),
          ),
        ],
      ),
    );
  }
}
