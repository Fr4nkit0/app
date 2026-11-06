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

  testWidgets('prefills username and password when remember me was on', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_remember_credentials': 'true',
      'auth_saved_username': 'mreparto',
      'auth_saved_password': 'secret',
    });

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller!.text, 'mreparto');
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

  testWidgets('the username field is plain text that does not capitalize', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final username = tester.widgetList<TextField>(find.byType(TextField)).first;
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsNothing);
    expect(username.keyboardType, TextInputType.text);
    expect(username.textCapitalization, TextCapitalization.none);
    expect(username.autocorrect, isFalse);
    expect(username.enableSuggestions, isFalse);
    expect(username.autofillHints, [AutofillHints.username]);
  });

  testWidgets('sends a username without an @ to the server', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json(422, {
        'errors': {
          'username': [
            'Estas credenciales no coinciden con nuestros registros.',
          ],
        },
      }),
    );

    await tester.pumpWidget(_app(adapter: adapter));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'jperez');
    await tester.enterText(fields.at(1), 'password');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect((adapter.requests.single.data as Map)['username'], 'jperez');
    expect(
      find.text('Estas credenciales no coinciden con nuestros registros.'),
      findsOneWidget,
    );
  });

  testWidgets('asks for the username when it is empty', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = FakeHttpAdapter(
      (_) => throw StateError('no network expected'),
    );

    await tester.pumpWidget(_app(adapter: adapter));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresá tu usuario'), findsOneWidget);
    expect(adapter.requests, isEmpty);
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
    await tester.enterText(fields.at(0), 'mreparto');
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
