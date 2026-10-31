import 'package:flutter/material.dart';

import 'package:app/core/presentation/rejection_message.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/customers/presentation/widgets/preference_dialog.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

const _fieldLabels = {
  'name': 'Nombre',
  'phone_number': 'Teléfono',
  'enabled': 'Activo',
  'street': 'Calle',
  'apartment': 'Departamento',
  'floor': 'Piso',
  'visual_reference': 'Referencia',
  'neighborhood': 'Barrio',
  'latitude': 'Latitud',
  'longitude': 'Longitud',
  'is_primary': 'Principal',
};

String _fieldLabel(String wire) {
  final field = wire.startsWith('address.') ? wire.substring(8) : wire;
  return _fieldLabels[field] ?? field;
}

String _value(Object? value) => switch (value) {
  null || '' => 'vacío',
  true => 'Sí',
  false => 'No',
  _ => '$value',
};

String _time(Object? value) =>
    PreferenceDetails.hhmm(value as String?) ?? '$value';

/// The refused [values] as the driver reads them: a preference as its day
/// and window ("Jueves 14:00–16:00"), any other record field by field.
List<String> refusedValueLines(Map<String, dynamic> values) {
  final day = values['day_of_week'];
  if (day is int) {
    final start = values['time_window_start'];
    final end = values['time_window_end'];
    final window = switch ((start, end)) {
      (null, null) => 'Todo el día',
      (null, _) => 'hasta ${_time(end)}',
      (_, null) => 'desde ${_time(start)}',
      _ => '${_time(start)}–${_time(end)}',
    };
    final off = values['enabled'] == false ? ' (desactivada)' : '';
    return ['${preferenceDayName(day)} $window$off'];
  }
  return [
    for (final MapEntry(:key, :value) in values.entries)
      '${_fieldLabel(key)}: ${_value(value)}',
  ];
}

/// What the server refused or dropped and why, plus what the device did.
class HistoryIssueLines extends StatelessWidget {
  const HistoryIssueLines({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = MarilinTokens.of(context);
    final muted = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: tokens.textMuted,
    );
    final reason = entry.rejectionReason;
    final fields = entry.changedFields;
    final lines = <Widget>[
      if (entry.status == PendingStatus.outdated) ...[
        if (fields != null && fields.isNotEmpty)
          Text('Campos: ${fields.map(_fieldLabel).join(', ')}', style: muted),
      ] else ...[
        for (final line in refusedValueLines(entry.rejectedValues ?? const {}))
          Text(
            line,
            style: muted.copyWith(
              fontWeight: FontWeight.w800,
              color: tokens.brandNavy,
            ),
          ),
        if (reason != null)
          Text(
            'Motivo: ${rejectionMessage(reason)}',
            style: muted.copyWith(
              fontWeight: FontWeight.w700,
              color: tokens.destructive,
            ),
          ),
        if (entry.rollback case final rollback?)
          Text(switch (rollback) {
            RejectionRollback.restored ||
            RejectionRollback.deleted => 'Se deshizo en el teléfono',
            RejectionRollback.kept => 'Se mantuvo en el teléfono',
          }, style: muted),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(padding: const EdgeInsets.only(top: 4), child: line),
      ],
    );
  }
}

/// The detail of a rejected or dropped record, with the way to put it away.
class HistoryIssueSheet extends StatelessWidget {
  const HistoryIssueSheet({
    super.key,
    required this.entry,
    required this.onDismiss,
  });

  final HistoryEntry entry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = MarilinTokens.of(context);
    final outdated = entry.status == PendingStatus.outdated;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              outdated ? 'Edición descartada' : 'Cambio rechazado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: tokens.brandNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${entry.customerName} · ${entry.description}',
              style: tokens.subtitle,
            ),
            if (outdated)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'El servidor tenía datos más nuevos; se muestran los del '
                  'servidor.',
                  style: tokens.subtitle,
                ),
              ),
            HistoryIssueLines(entry: entry),
            const SizedBox(height: 20),
            FilledButton(onPressed: onDismiss, child: const Text('Descartar')),
          ],
        ),
      ),
    );
  }
}
