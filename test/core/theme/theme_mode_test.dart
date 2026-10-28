import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/theme/theme_mode_controller.dart';

void main() {
  group('theme mode', () {
    test('follows the system until the driver picks one', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('restores the saved choice', () async {
      FlutterSecureStorage.setMockInitialValues({ThemeModeController.storageKey: 'dark'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider);
      await pumpEventQueue();

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('remembers a new choice on the phone', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).choose(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(await const FlutterSecureStorage().read(key: ThemeModeController.storageKey), 'light');
    });

    test('ignores a stored value it does not know', () async {
      FlutterSecureStorage.setMockInitialValues({ThemeModeController.storageKey: 'sepia'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeModeProvider);
      await pumpEventQueue();

      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });

  group('themes', () {
    test('the dark theme is dark and carries the dark tokens', () {
      final dark = AppTheme.darkTheme;

      expect(dark.brightness, Brightness.dark);
      expect(dark.extension<MarilinTokens>(), MarilinTokens.dark);
      expect(dark.scaffoldBackgroundColor, MarilinTokens.dark.scaffoldMuted);
      expect(AppTheme.lightTheme.extension<MarilinTokens>(), MarilinTokens.light);
    });

    test('dark text is light on a dark surface', () {
      final tokens = MarilinTokens.dark;

      expect(tokens.surface.computeLuminance(), lessThan(0.1));
      expect(tokens.brandNavy.computeLuminance(), greaterThan(0.8));
    });
  });
}
