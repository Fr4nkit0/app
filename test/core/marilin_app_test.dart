import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:app/main.dart';

/// Keeps the app on its loading screen, so no feature needs a database.
class _CheckingSession extends AuthController {
  @override
  AuthState build() => AuthState(isLoading: true);
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('the time picker speaks Spanish', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(_CheckingSession.new)],
        child: const MarilinApp(),
      ),
    );
    await tester.pump();

    showTimePicker(
      context: tester.element(find.byType(CircularProgressIndicator)),
      initialTime: const TimeOfDay(hour: 15, minute: 30),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('OK'), findsNothing);
    expect(find.text('AM'), findsNothing);
  });

  test('the Clientes tab carries no customer-count badge', () {
    final shell = File('lib/main.dart').readAsStringSync();

    expect(shell, isNot(contains('customerCountProvider')));
    expect(shell, isNot(contains('Badge')));
  });
}
