import 'package:app/core/network/dio_client.dart';
import 'package:app/features/auth/login_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

Widget _app({FakeHttpAdapter? adapter}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter =
        adapter ??
        FakeHttpAdapter((_) => throw StateError('no network expected'));
  return ProviderScope(
    overrides: [
      dioProvider.overrideWithValue(dio),
      secureStorageProvider.overrideWithValue(const FlutterSecureStorage()),
    ],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('prefills email and password when remember me was on', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_remember_credentials': 'true',
      'auth_saved_email': 'marcos@marilin.test',
      'auth_saved_password': 'secret',
    });

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller!.text, 'marcos@marilin.test');
    expect(fields[1].controller!.text, 'secret');
    final remember = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(remember.value, isTrue);
  });

  testWidgets('remember me is a plain checkbox with no helper text', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final remember = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(find.text('Recordarme'), findsOneWidget);
    expect(remember.subtitle, isNull);
  });

  testWidgets('starts with empty fields on a fresh install', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller!.text, isEmpty);
    expect(fields[1].controller!.text, isEmpty);
  });

  testWidgets('the email field does not capitalize or autocorrect', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final email = tester.widgetList<TextField>(find.byType(TextField)).first;
    expect(email.keyboardType, TextInputType.emailAddress);
    expect(email.textCapitalization, TextCapitalization.none);
    expect(email.autocorrect, isFalse);
    expect(email.enableSuggestions, isFalse);
  });

  testWidgets('the error banner is read only once', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final semantics = tester.ensureSemantics();
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json(422, {
        'message': 'These credentials do not match our records.',
      }),
    );

    await tester.pumpWidget(_app(adapter: adapter));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'marcos@marilin.test');
    await tester.enterText(fields.at(1), 'wrong');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('No pudimos iniciar sesión')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('credenciales|credentials')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('Error al iniciar')), findsNothing);
    semantics.dispose();
  });
}
