import 'package:flutter/material.dart';

import 'package:app/features/visits/domain/models/visit_outcome.dart';

/// The new outcome and notes of an edited visit; empty notes are null.
typedef VisitEdit = ({VisitOutcome outcome, String? notes});

/// Changes the outcome and notes of a closed visit; pops a [VisitEdit] on
/// save. [outcomes] must already exclude the reschedule.
class VisitEditSheet extends StatefulWidget {
  const VisitEditSheet({
    super.key,
    required this.outcomes,
    this.initialOutcome,
    this.initialNotes,
  });

  final List<VisitOutcome> outcomes;
  final VisitOutcome? initialOutcome;
  final String? initialNotes;

  @override
  State<VisitEditSheet> createState() => _VisitEditSheetState();
}

class _VisitEditSheetState extends State<VisitEditSheet> {
  late VisitOutcome? _selected = widget.outcomes
      .where((o) => o.id == widget.initialOutcome?.id)
      .firstOrNull;
  late final _notes = TextEditingController(text: widget.initialNotes);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final outcome = _selected;
    if (outcome == null) return;
    final notes = _notes.text.trim();
    Navigator.of(
      context,
    ).pop<VisitEdit>((outcome: outcome, notes: notes.isEmpty ? null : notes));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editar resultado',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final outcome in widget.outcomes)
                ChoiceChip(
                  label: Text(outcome.name),
                  selected: _selected?.id == outcome.id,
                  onSelected: (_) => setState(() => _selected = outcome),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Observaciones de la visita (opcional)',
              alignLabelWithHint: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selected == null ? null : _save,
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
