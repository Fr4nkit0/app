import 'package:app/features/customers/domain/models/salta_neighborhoods.dart';
import 'package:app/features/customers/presentation/providers/neighborhoods_provider.dart';
import 'package:app/features/customers/presentation/widgets/neighborhood_search_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feeds the neighborhood search sheet with the stored catalog.
class NeighborhoodPickerSheet extends ConsumerWidget {
  const NeighborhoodPickerSheet({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The bundled list covers the first frame and a failed read, so the
    // driver can always pick a neighborhood.
    final names =
        ref.watch(neighborhoodNamesProvider).value ?? saltaNeighborhoods;
    return NeighborhoodSearchBottomSheet(
      neighborhoods: names,
      onSelected: onSelected,
    );
  }
}
