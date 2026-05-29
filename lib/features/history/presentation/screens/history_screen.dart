import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/widgets/empty_state.dart';
import 'package:app/core/widgets/screen_header.dart';
import 'package:app/features/history/presentation/providers/history_list_provider.dart';
import 'package:app/features/history/presentation/widgets/history_entry_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(title: 'Historial'),
            Expanded(
              child: historyAsync.when(
                data: (entries) => entries.isEmpty
                    ? const EmptyState(
                        icon: Icons.history_outlined,
                        title: 'Sin historial',
                        message: 'Las ventas y visitas van a aparecer acá.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: entries.length,
                        itemBuilder: (context, index) =>
                            HistoryEntryTile(entry: entries[index]),
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    const Center(child: Text('Error al cargar historial')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
