import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:app/features/customers/presentation/widgets/new_customer_button.dart';

import '../../../../support/real_fonts.dart';

/// Lets the in-memory database answer; its queries run outside fake time.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  late AppDatabase db;

  setUpAll(() async {
    expect(await loadRealFonts(), isTrue, reason: 'Roboto was not found in the Flutter SDK cache');
  });

  // Nine customers with a phone, as on the field-test device.
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    for (var i = 1; i <= 9; i++) {
      await db.into(db.customerTable).insert(
            CustomerTableCompanion.insert(
              customerId: drift.Value('c-$i'),
              name: 'Cliente $i',
              phone: drift.Value('387400000$i'),
            ),
          );
    }
  });
  tearDown(() => db.close());

  testWidgets('at the end of the list the new-customer button leaves the last WhatsApp button free', (tester) async {
    // Moto G6 (1080x2160), the device of the field test.
    tester.view.physicalSize = const Size(1080, 2160);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          // The list lives in a tab above the app's bottom navigation bar.
          home: Scaffold(
            body: const CustomerListScreen(),
            bottomNavigationBar: NavigationBar(
              destinations: const [
                NavigationDestination(icon: Icon(Icons.route), label: 'Ruta'),
                NavigationDestination(icon: Icon(Icons.people), label: 'Clientes'),
              ],
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Cliente 1'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await settle(tester);

    final whatsapp = find.byTooltip('WhatsApp');
    final lastWhatsapp = tester.getRect(whatsapp.last);
    final fab = tester.getRect(find.byType(NewCustomerButton));
    expect(find.text('Cliente 9'), findsOneWidget);
    expect(lastWhatsapp.overlaps(fab), isFalse, reason: 'WhatsApp $lastWhatsapp, FAB $fab');
    expect(whatsapp.last.hitTestable(), findsOneWidget);

    // Drift schedules a zero-duration timer when a watched query is cancelled.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
