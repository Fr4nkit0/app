import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/avatar_utils.dart';

void main() {
  group('AvatarUtils', () {
    group('getInitials', () {
      test('should extract up to 2 uppercase initials from a full name', () {
        expect(AvatarUtils.getInitials('Juan Pérez'), equals('JP'));
        expect(AvatarUtils.getInitials('Marilin'), equals('MA'));
        expect(AvatarUtils.getInitials(''), equals(''));
        expect(AvatarUtils.getInitials('  '), equals(''));
        expect(AvatarUtils.getInitials('juan pérez'), equals('JP'));
        expect(AvatarUtils.getInitials('Single'), equals('SI'));
        expect(AvatarUtils.getInitials(' A  B '), equals('AB'));
      });
    });

    group('getPastelColor', () {
      test('should calculate deterministic color', () {
        final color1 = AvatarUtils.getPastelColor('Juan');
        final color2 = AvatarUtils.getPastelColor('Juan');
        final color3 = AvatarUtils.getPastelColor('Pérez');

        expect(color1, equals(color2));
        expect(color1, isNot(equals(color3)));
      });
    });

    group('getColors', () {
      test('should compute background and foreground colors', () {
        final colorsDefault = AvatarUtils.getColors('Juan');
        expect(colorsDefault.background, isA<Color>());
        expect(colorsDefault.foreground, isA<Color>());

        final colorsSelected = AvatarUtils.getColors('Juan', selected: true);
        expect(colorsSelected.background, equals(const Color(0xFF1565C0)));
        expect(colorsSelected.foreground, equals(Colors.white));

        final customBaseColor = Colors.red;
        final colorsCustom = AvatarUtils.getColors(
          'Juan',
          baseColor: customBaseColor,
        );
        expect(
          colorsCustom.background,
          equals(customBaseColor.withValues(alpha: 0.1)),
        );
        expect(colorsCustom.foreground, equals(customBaseColor));
      });
    });
  });
}
