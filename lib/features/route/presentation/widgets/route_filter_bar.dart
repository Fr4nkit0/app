import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/widgets/core_search_bar.dart';
import 'package:app/features/route/domain/models/stop_status.dart';

/// The filters over the day's route: a customer search, a neighborhood
/// picker, status chips with their counts and, while something is
/// filtered, how many stops are shown.
class RouteFilterBar extends StatelessWidget {
  const RouteFilterBar({
    super.key,
    required this.controller,
    required this.neighborhood,
    required this.status,
    required this.statusCounts,
    required this.shownCount,
    required this.totalCount,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onPickNeighborhood,
    required this.onClearNeighborhood,
    required this.onStatusChanged,
    required this.onClearAll,
    this.searchFieldKey,
  });

  final TextEditingController controller;
  final String? neighborhood;
  final StopStatus? status;

  /// Stops per status, with null for every stop.
  final Map<StopStatus?, int> statusCounts;
  final int shownCount;
  final int totalCount;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final VoidCallback onPickNeighborhood;
  final VoidCallback onClearNeighborhood;
  final ValueChanged<StopStatus?> onStatusChanged;
  final VoidCallback onClearAll;
  final Key? searchFieldKey;

  static const neighborhoodButtonKey = Key('route-neighborhood-button');

  static const _statusLabels = <(StopStatus?, String)>[
    (null, 'Todas'),
    (StopStatus.pending, 'Pendientes'),
    (StopStatus.done, 'Visitadas'),
    (StopStatus.absent, 'Ausentes'),
    (StopStatus.rescheduled, 'Reprogramadas'),
  ];

  bool get _filtering =>
      controller.text.trim().isNotEmpty ||
      neighborhood != null ||
      status != null;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => CoreSearchBar(
                  key: searchFieldKey,
                  controller: controller,
                  hintText: 'Buscar cliente',
                  fillColor: tokens.surface,
                  onChanged: onQueryChanged,
                  onClear: value.text.isEmpty ? null : onClearQuery,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _NeighborhoodButton(
              key: neighborhoodButtonKey,
              neighborhood: neighborhood,
              onPick: onPickNeighborhood,
              onClear: onClearNeighborhood,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (value, label) in _statusLabels)
                if (value == null ||
                    (statusCounts[value] ?? 0) > 0 ||
                    status == value)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$label ${statusCounts[value] ?? 0}'),
                      selected: status == value,
                      showCheckmark: false,
                      onSelected: (_) => onStatusChanged(value),
                    ),
                  ),
            ],
          ),
        ),
        if (_filtering)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shownCount == 1
                        ? '1 de $totalCount paradas'
                        : '$shownCount de $totalCount paradas',
                    style: TextStyle(
                      color: tokens.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 40)),
                  child: const Text('Limpiar filtros'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Barrio" until one is picked; then the neighborhood with a clear
/// control. Tapping the label (re)opens the picker.
class _NeighborhoodButton extends StatelessWidget {
  const _NeighborhoodButton({
    super.key,
    required this.neighborhood,
    required this.onPick,
    required this.onClear,
  });

  final String? neighborhood;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;
    final selected = neighborhood;
    if (selected == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.place_outlined, size: 20),
        label: const Text('Barrio'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          foregroundColor: tokens.ink,
          side: BorderSide(color: tokens.border),
          backgroundColor: tokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    // An active filter reads as a filled pill: white on brand blue keeps
    // its contrast under glare in both themes.
    const onBlue = Colors.white;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 168, minHeight: 48),
      child: Material(
        color: MarilinColors.brandBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InkWell(
                onTap: onPick,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place, size: 18, color: onBlue),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          selected,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: onBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Quitar barrio',
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18, color: onBlue),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
