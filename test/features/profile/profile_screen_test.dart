import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/theme/theme_mode_controller.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/profile/profile_screen.dart';

class _SignedIn extends AuthController {
  @override
  AuthState build() => AuthState(isAuthenticated: true, displayName: 'Esteban Benítez');
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<ProviderContainer> pumpProfile(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [authControllerProvider.overrideWith(_SignedIn.new)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows who is signed in', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Esteban Benítez'), findsOneWidget);
  });

  testWidgets('offers the phone theme, light and dark, starting on the phone theme', (tester) async {
    final container = await pumpProfile(tester);

    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('choosing Oscuro switches and saves the theme', (tester) async {
    final container = await pumpProfile(tester);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(await const FlutterSecureStorage().read(key: ThemeModeController.storageKey), 'dark');
  });

  testWidgets('has the sign out action', (tester) async {
    await pumpProfile(tester);

    expect(find.widgetWithText(OutlinedButton, 'Cerrar sesión'), findsOneWidget);
  });

  testWidgets('the profile button opens the profile', (tester) async {
    final container = ProviderContainer(overrides: [authControllerProvider.overrideWith(_SignedIn.new)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const Scaffold(body: ProfileButton())),
      ),
    );

    await tester.tap(find.byTooltip('Mi perfil'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}
