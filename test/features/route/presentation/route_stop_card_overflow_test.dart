import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/widgets/route_stop_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/real_fonts.dart';

const _longName =
    'Distribuidora Hermanos Rodríguez y Compañía Sociedad Anónima';

void main() {
  setUpAll(() async {
    expect(
      await loadRealFonts(),
      isTrue,
      reason: 'Roboto was not found in the Flutter SDK cache',
    );
  });

  testWidgets('a 60-character name wraps to two lines with an ellipsis', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final stop = RouteStop(
      id: 's-1',
      customer: Customer(
        id: 'c-1',
        name: _longName,
        phone: '3874000000',
        addresses: const [],
        preferences: const [],
      ),
      status: StopStatus.pending,
      scheduledAt: DateTime(2026, 10, 28, 9),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RouteStopCard(stop: stop, onTap: () {}),
            ),
          ),
        ),
      ),
    );

    final name = tester.widget<Text>(find.text(_longName));
    expect(name.maxLines, 2);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
