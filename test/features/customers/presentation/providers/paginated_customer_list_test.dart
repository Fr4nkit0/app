import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    // The customers screen watches the list; Riverpod pauses providers nobody listens to.
    container.listen(paginatedCustomerListProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  test('customers that arrive after the list was opened empty show up without a manual refresh', () async {
    final notifier = container.read(paginatedCustomerListProvider.notifier);
    await notifier.loadNextPage();
    expect(container.read(paginatedCustomerListProvider).customers, isEmpty);

    // A sync writes the driver's customers into the local database.
    await db.into(db.customerTable).insert(
          CustomerTableCompanion.insert(customerId: const drift.Value('c-1'), name: 'Hotel Altos de la Viña'),
        );
    await settle();

    expect(
      container.read(paginatedCustomerListProvider).customers.map((c) => c.name),
      ['Hotel Altos de la Viña'],
    );
  });

  test('a customer renamed by a pull is shown with its new name', () async {
    await db.into(db.customerTable).insert(
          CustomerTableCompanion.insert(customerId: const drift.Value('c-1'), name: 'Prueba'),
        );
    await container.read(paginatedCustomerListProvider.notifier).loadNextPage();
    await settle();

    await (db.update(db.customerTable)..where((t) => t.customerId.equals('c-1')))
        .write(const CustomerTableCompanion(name: drift.Value('Familia Gonzalez')));
    await settle();

    expect(
      container.read(paginatedCustomerListProvider).customers.map((c) => c.name),
      ['Familia Gonzalez'],
    );
  });
}
