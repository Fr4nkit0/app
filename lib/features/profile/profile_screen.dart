import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/theme/theme_mode_controller.dart';
import 'package:app/core/widgets/screen_header.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/auth/logout_button.dart';
import 'package:app/features/history/presentation/widgets/history_sync_status_card.dart';
import 'package:app/features/profile/widgets/profile_avatar.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';

/// The driver's own screen: who is signed in, how the sync is doing, the
/// theme, and signing out. Opened from the avatar on the route screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authControllerProvider).displayName ?? 'Repartidor';
    final mode = ref.watch(themeModeProvider);
    final syncStatus =
        ref.watch(syncStatusProvider).value ?? const SyncStatus();
    final isSyncRunning = ref.watch(syncRunningProvider).value ?? false;
    final tokens = context.marilin;

    return Scaffold(
      backgroundColor: tokens.scaffoldMuted,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Mi perfil',
              onBackPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  _IdentityBlock(name: name),
                  const SizedBox(height: 32),
                  const _SectionTitle('Sincronización'),
                  const SizedBox(height: 10),
                  HistorySyncStatusCard(
                    status: syncStatus,
                    isRunning: isSyncRunning,
                    onSync: () => ref.read(syncEngineProvider).runCycle(),
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle('Apariencia'),
                  const SizedBox(height: 10),
                  _ThemeCard(
                    mode: mode,
                    onChanged: (selected) =>
                        ref.read(themeModeProvider.notifier).choose(selected),
                  ),
                  const SizedBox(height: 36),
                  _SignOutBlock(
                    pendingCount: syncStatus.pendingCount,
                    onSignOut: () => confirmAndLogout(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;

    return Column(
      children: [
        ProfileAvatar(name: name, size: 88),
        const SizedBox(height: 16),
        Text(
          name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: tokens.ink,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 15,
              color: tokens.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'Repartidor',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: tokens.inkSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: context.marilin.ink,
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Sistema sigue el tema del teléfono.',
            style: tokens.subtitle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 14),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Sistema'),
                icon: Icon(Icons.brightness_auto_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Claro'),
                icon: Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Oscuro'),
                icon: Icon(Icons.dark_mode_rounded),
              ),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onChanged(selection.first),
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
              side: WidgetStatePropertyAll(BorderSide(color: tokens.border)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? tokens.brandBlue.withValues(alpha: 0.12)
                    : tokens.surface,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? tokens.brandBlue
                    : tokens.inkSecondary,
              ),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutBlock extends StatelessWidget {
  const _SignOutBlock({required this.pendingCount, required this.onSignOut});

  final int pendingCount;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;
    final warning = tokens.vivid(tokens.accent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pendingCount > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.soft(MarilinColors.accent.withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_upload_outlined, size: 20, color: warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pendingCount == 1
                        ? 'Tenés 1 cambio sin sincronizar. '
                              'Sincronizá antes de cerrar sesión.'
                        : 'Tenés $pendingCount cambios sin sincronizar. '
                              'Sincronizá antes de cerrar sesión.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: onSignOut,
          style: OutlinedButton.styleFrom(
            foregroundColor: tokens.destructive,
            side: BorderSide(
              color: tokens.destructive.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
