import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/string_utils.dart';
import 'package:app/core/widgets/core_search_bar.dart';
import 'package:app/features/route/domain/models/route_stop_filter.dart';

/// Bottom sheet listing the neighborhoods of the day's route with their
/// stop counts; typing narrows the list and one tap picks a neighborhood.
class NeighborhoodPickerSheet extends StatefulWidget {
  const NeighborhoodPickerSheet({
    super.key,
    required this.neighborhoods,
    required this.selected,
    required this.onSelected,
  });

  final List<RouteNeighborhood> neighborhoods;
  final String? selected;

  /// The picked neighborhood; null for every neighborhood.
  final ValueChanged<String?> onSelected;

  static const searchFieldKey = Key('neighborhood-search-field');

  @override
  State<NeighborhoodPickerSheet> createState() =>
      _NeighborhoodPickerSheetState();
}

class _NeighborhoodPickerSheetState extends State<NeighborhoodPickerSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<RouteNeighborhood> get _matching => [
    for (final n in widget.neighborhoods)
      if (StringUtils.wordStartMatch(_controller.text, n.name)) n,
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;
    final matching = _matching;
    final selectedKey = RouteStopFilter.neighborhoodKey(widget.selected);
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'Elegí un barrio',
                style: TextStyle(
                  color: tokens.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (widget.neighborhoods.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: CoreSearchBar(
                  key: NeighborhoodPickerSheet.searchFieldKey,
                  controller: _controller,
                  hintText: 'Buscar barrio',
                  onChanged: (_) => setState(() {}),
                  onClear: _controller.text.isEmpty
                      ? null
                      : () => setState(_controller.clear),
                ),
              ),
            Flexible(
              child: widget.neighborhoods.isEmpty
                  ? _Message('Las paradas de hoy no tienen barrio cargado.')
                  : matching.isEmpty
                  ? _Message('Ningún barrio coincide.')
                  : ListView(
                      shrinkWrap: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        if (widget.selected != null && _controller.text.isEmpty)
                          _NeighborhoodTile(
                            label: 'Todos los barrios',
                            selected: false,
                            onTap: () => widget.onSelected(null),
                          ),
                        for (final n in matching)
                          _NeighborhoodTile(
                            label: n.name,
                            count: n.stopCount,
                            selected:
                                RouteStopFilter.neighborhoodKey(n.name) ==
                                selectedKey,
                            onTap: () => widget.onSelected(n.name),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeighborhoodTile extends StatelessWidget {
  const _NeighborhoodTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;
    final blue = tokens.vivid(MarilinColors.brandBlue);
    final count = this.count;
    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      selected: selected,
      selectedTileColor: blue.withValues(alpha: 0.10),
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          color: selected ? blue : tokens.ink,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null)
            Text(
              count == 1 ? '1 parada' : '$count paradas',
              style: TextStyle(
                color: tokens.textMuted,
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          if (selected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check, color: blue, size: 20),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    child: Text(
      text,
      style: TextStyle(color: context.marilin.textMuted, fontSize: 14),
    ),
  );
}
