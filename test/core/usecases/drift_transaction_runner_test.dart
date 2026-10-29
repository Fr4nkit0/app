import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/core/usecases/transaction_runner.dart';

void main() {
  late AppDatabase db;
  late TransactionRunner transaction;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    transaction = driftTransactionRunner(db);
  });
  tearDown(() => db.close());

  Future<void> insertCustomer() => db
      .into(db.customerTable)
      .insert(
        CustomerTableCompanion.insert(
          customerId: const Value('cust-1'),
          name: 'José',
        ),
      );

  test('returns the value of the action and keeps its writes', () async {
    final result = await transaction(() async {
      await insertCustomer();
      return 42;
    });

    expect(result, 42);
    expect(await db.select(db.customerTable).get(), hasLength(1));
  });

  test('rethrows a DomainFailure unchanged and rolls back', () async {
    const failure = ValidationFailure('Sin ítems');

    await expectLater(
      transaction(() async {
        await insertCustomer();
        throw failure;
      }),
      throwsA(same(failure)),
    );
    expect(await db.select(db.customerTable).get(), isEmpty);
  });

  test(
    'wraps any other exception in a StorageFailure and rolls back',
    () async {
      final cause = Exception('disk full');

      await expectLater(
        transaction(() async {
          await insertCustomer();
          throw cause;
        }),
        throwsA(
          isA<StorageFailure>().having((f) => f.cause, 'cause', same(cause)),
        ),
      );
      expect(await db.select(db.customerTable).get(), isEmpty);
    },
  );

  test('wraps a database error in a StorageFailure', () async {
    await expectLater(
      transaction(() async {
        await insertCustomer();
        await insertCustomer(); // duplicate primary key
      }),
      throwsA(isA<StorageFailure>()),
    );
    expect(await db.select(db.customerTable).get(), isEmpty);
  });
}
