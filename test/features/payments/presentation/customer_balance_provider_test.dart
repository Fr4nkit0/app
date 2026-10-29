import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/payments/data/repositories/customer_account.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';

/// The visit's debt (S29) comes from this provider, backed by the customer
/// account.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  /// Listens while reading: Riverpod pauses a provider nobody listens to.
  Future<double> debtOf(String customerId) {
    final provider = customerBalanceProvider(customerId);
    container.listen(provider, (_, _) {});
    return container.read(provider.future);
  }

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('is 0 for a customer without an account', () async {
    expect(await debtOf('c-1'), 0);
  });

  test('is the balance of the customer account', () async {
    await CustomerAccount(db).post('c-1', 1500);

    expect(await debtOf('c-1'), 1500);
  });
}
