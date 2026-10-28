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

    test('dark text is light on a dark glass card', () {
      final tokens = MarilinTokens.dark;
      // The card is translucent: what the eye sees is the card over the background.
      final card = Color.alphaBlend(tokens.surface, tokens.scaffoldMuted);

      expect(card.computeLuminance(), lessThan(0.05));
      expect(tokens.ink.computeLuminance(), greaterThan(0.8));
    });

    test('a pastel status tile keeps its hue in dark instead of turning grey', () {
      const pastelBlue = Color(0xFFEFF6FF);

      expect(MarilinTokens.light.soft(pastelBlue), pastelBlue);
      final wash = HSLColor.fromColor(MarilinTokens.dark.soft(pastelBlue));
      expect(wash.hue, closeTo(HSLColor.fromColor(pastelBlue).hue, 1));
      expect(wash.saturation, greaterThanOrEqualTo(0.6));
      expect(wash.alpha, lessThan(0.2));
    });

    test('a dark-green status icon is lifted in dark and untouched in light', () {
      const green800 = Color(0xFF2E7D32);

      expect(MarilinTokens.light.vivid(green800), green800);
      final lifted = HSLColor.fromColor(MarilinTokens.dark.vivid(green800));
      expect(lifted.lightness, closeTo(0.62, 0.01));
      expect(lifted.hue, closeTo(HSLColor.fromColor(green800).hue, 1));
    });
  });
}
