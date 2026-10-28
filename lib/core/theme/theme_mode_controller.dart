import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/network/dio_client.dart';

/// The driver's theme choice: the phone's (system), or always light, or always
/// dark. Saved on the phone and restored on the next start.
class ThemeModeController extends Notifier<ThemeMode> {
  static const storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.system;
  }

  Future<void> choose(ThemeMode mode) async {
    state = mode;
    await ref.read(secureStorageProvider).write(key: storageKey, value: mode.name);
  }

  Future<void> _restore() async {
    final saved = await ref.read(secureStorageProvider).read(key: storageKey);
    final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
    if (mode != null && mode != state) state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
