import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/domain/usecases/disable_customer.usecase.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// Disables the customer and queues it, then fails.
class _FailingAfterWriteRepository extends DriftCustomerRepository {
  _FailingAfterWriteRepository(super.db);

  @override
  Future<void> disableCustomer(String customerId) async {
    await super.disableCustomer(customerId);
    throw Exception('disk full');
  }
}

void main() {
  late AppDatabase db;
  final longAgo = DateTime(2020, 1, 1);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    for (final (id, name) in [('cust-1', 'Kiosco Norte'), ('cust-2', 'Almacén Sur')]) {
      await db.into(db.customerTable).insert(
        CustomerTableCompanion.insert(
          customerId: Value(id),
          name: name,
          lastModifiedDate: Value(longAgo),
        ),
      );
    }
  });
  tearDown(() => db.close());

  DisableCustomerUseCase useCase([CustomerRepository? repo]) =>
      DisableCustomerUseCase(
        customerRepository: repo ?? DriftCustomerRepository(db),
        transaction: driftTransactionRunner(db),
      );

  Future<CustomerTableData> row(String id) => (db.select(
    db.customerTable,
  )..where((t) => t.customerId.equals(id))).getSingle();

  Future<void> expectUnchanged() async {
    final customer = await row('cust-1');
    expect(customer.enabled, isTrue);
    expect(customer.lastModifiedDate, longAgo);
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
  }

  test('disables the customer, touches its modified date and queues one '
      'customer update', () async {
    await useCase().execute('cust-1');

    final customer = await row('cust-1');
    expect(customer.enabled, isFalse);
    expect(customer.lastModifiedDate.isAfter(longAgo), isTrue);
    expect((await row('cust-2')).enabled, isTrue);

    final change = await db.select(db.pendingChangeTable).getSingle();
    expect(change.entity, PendingEntity.customer.wireName);
    expect(change.entityId, 'cust-1');
    expect(change.action, PendingAction.update.wireName);
  });

  test('the disabled customer leaves the list, the search and the count '
      'right away', () async {
    final repo = DriftCustomerRepository(db);

    await useCase().execute('cust-1');

    List<String> ids(Iterable<dynamic> customers) =>
        [for (final c in customers) c.id as String];
    expect(ids(await repo.watchAllCustomers().first), ['cust-2']);
    expect(ids(await repo.getCustomersPage(page: 0, pageSize: 10)), ['cust-2']);
    expect(
      ids(await repo.searchCustomers(query: 'Kiosco', page: 0, pageSize: 10)),
      isEmpty,
    );
    expect(await repo.watchCustomerCount().first, 1);
  });

  test('a missing customer throws a NotFoundFailure and queues nothing', () async {
    await expectLater(
      useCase().execute('ghost'),
      throwsA(isA<NotFoundFailure>()),
    );
    await expectUnchanged();
  });

  test('a failure mid-way leaves the customer enabled and the queue empty', () async {
    await expectLater(
      useCase(_FailingAfterWriteRepository(db)).execute('cust-1'),
      throwsA(isA<StorageFailure>()),
    );
    await expectUnchanged();
  });
}
