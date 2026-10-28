import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/core/network/dio_client.dart';

/// The driver's theme choice: the phone's (system), or always light, or always
/// dark. Saved on the phone and restored on the next start.
class ThemeModeController extends Notifier<ThemeMode> {
  static const storageKey = 'theme_mode';

  /// The saved choice, read in main() before the first frame so a dark choice
  /// does not flash light while the app starts.
  static ThemeMode initial = ThemeMode.system;

  static Future<ThemeMode> readSaved(FlutterSecureStorage storage) async {
    return _parse(await storage.read(key: storageKey)) ?? ThemeMode.system;
  }

  static ThemeMode? _parse(String? saved) =>
      ThemeMode.values.where((m) => m.name == saved).firstOrNull;

  /// The driver chose while the saved value was still being read: theirs wins.
  bool _chosen = false;

  @override
  ThemeMode build() {
    _restore();
    return initial;
  }

  Future<void> choose(ThemeMode mode) async {
    _chosen = true;
    state = mode;
    await ref.read(secureStorageProvider).write(key: storageKey, value: mode.name);
  }

  Future<void> _restore() async {
    final mode = _parse(await ref.read(secureStorageProvider).read(key: storageKey));
    if (_chosen || mode == null || mode == state) return;
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
