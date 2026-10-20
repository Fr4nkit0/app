import 'package:app/core/network/dio_client.dart';
import 'package:app/features/auth/login_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

Widget _app() {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = FakeHttpAdapter(
      (_) => throw StateError('no network expected'),
    );
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

  testWidgets('prefills only the email when remember me was on', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_remember_credentials': 'true',
      'auth_saved_email': 'marcos@marilin.test',
      'auth_saved_password': 'legacy-secret',
    });

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller!.text, 'marcos@marilin.test');
    expect(fields[1].controller!.text, isEmpty);
    expect(find.text('Recordarme'), findsOneWidget);
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
}
