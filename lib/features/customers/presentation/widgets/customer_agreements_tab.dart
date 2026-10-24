import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer_agreement.dart';
import 'package:app/features/customers/presentation/providers/customer_agreements_provider.dart';
import 'package:app/features/customers/presentation/widgets/new_agreement_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Acuerdos tab of the customer profile: the customer's price agreements
/// and the entry point to create one.
class CustomerAgreementsTab extends ConsumerWidget {
  const CustomerAgreementsTab({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreements = ref.watch(customerAgreementsProvider(customerId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => showNewAgreementSheet(context, customerId),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo acuerdo'),
            ),
          ),
          const SizedBox(height: 12),
          agreements.when(
            data: (list) => list.isEmpty
                ? const _EmptyAgreements()
                : Column(
                    children: [
                      for (final a in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AgreementCard(agreement: a),
                        ),
                    ],
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('Error al cargar acuerdos: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAgreements extends StatelessWidget {
  const _EmptyAgreements();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.handshake_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Sin acuerdos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1B3E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Este cliente no tiene acuerdos de precio.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

/// Presentational card of one agreement.
class AgreementCard extends StatelessWidget {
  const AgreementCard({super.key, required this.agreement});

  final CustomerAgreement agreement;

  static String formatMoney(double value) => value == value.roundToDouble()
      ? '\$${value.toStringAsFixed(0)}'
      : '\$${value.toStringAsFixed(2).replaceAll('.', ',')}';

  static String formatDate(String day) {
    final p = day.split('-');
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  static (String, Color) _chip(AgreementStatus status) => switch (status) {
    AgreementStatus.inForce => ('Vigente', const Color(0xFF15803D)),
    AgreementStatus.ended => ('Finalizado', const Color(0xFF64748B)),
    AgreementStatus.future => ('Futuro', MarilinColors.brandBlue),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _chip(agreement.status);
    final validity = agreement.validTo == null
        ? 'Desde ${formatDate(agreement.validFrom)}'
        : '${formatDate(agreement.validFrom)} al ${formatDate(agreement.validTo!)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  agreement.productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1B3E),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatMoney(agreement.unitPrice),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1B3E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            validity,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          if (agreement.reason != null) ...[
            const SizedBox(height: 4),
            Text(
              agreement.reason!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
          if (!agreement.isSynced) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sync_outlined, size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  'Pendiente de sincronizar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
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
