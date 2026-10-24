import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/data/repositories/drift.customer_agreement.repository.dart';
import 'package:app/features/customers/domain/models/customer_agreement.dart';
import 'package:app/features/products/data/repositories/drift.product.repository.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

void main() {
  late AppDatabase db;
  late DriftCustomerAgreementRepository sut;
  final today = DateTime(2026, 10, 22);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftCustomerAgreementRepository(db);
    await db.into(db.customerTable).insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
          ),
        );
    await db.into(db.productTable).insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('p-1'),
            name: 'Agua 20L',
            price: 1500,
          ),
        );
  });
  tearDown(() => db.close());

  Future<Resource<String>> create({
    double price = 1200,
    String validFrom = '2026-10-22',
    String? validTo,
    String? reason,
  }) => sut.create(
    customerId: 'c-1',
    productId: 'p-1',
    unitPrice: price,
    validFrom: validFrom,
    validTo: validTo,
    reason: reason,
  );

  test('create stores the agreement and queues it in the same step', () async {
    final result = await create(reason: 'Cliente mayorista');

    final id = (result as Success<String>).value;
    final row = await db.select(db.customerAgreementTable).getSingle();
    expect(row.agreementId, id);
    expect(row.serverId, isNull);
    expect(row.unitPrice, 1200);
    expect(row.reason, 'Cliente mayorista');

    final pending = await DriftPendingChangeRepository(db).getPending();
    expect(pending, hasLength(1));
    expect(pending.single.entity, PendingEntity.customerAgreement);
    expect(pending.single.entityId, id);
    expect(pending.single.action, PendingAction.insert);
  });

  test('create changes the price the customer pays right away', () async {
    final result = await create();

    final products = await DriftProductRepository(db)
        .watchProductsFor('c-1')
        .first;
    expect(products.single.price, 1200);
    expect(products.single.agreementId, isNull);
    expect(products.single.agreementUuid, (result as Success<String>).value);
  });

  test('create rejects invalid input and stores nothing', () async {
    for (final result in [
      await create(price: 0),
      await create(price: 12.345),
      await create(validFrom: '2026-10-22', validTo: '2026-10-21'),
      await create(reason: 'x' * 501),
    ]) {
      expect(result, isA<Error<String>>());
    }
    expect(await db.select(db.customerAgreementTable).get(), isEmpty);
    expect(await DriftPendingChangeRepository(db).getPending(), isEmpty);
  });

  test('watch lists the agreements in force first with their status', () async {
    await create(price: 1000, validFrom: '2026-01-01', validTo: '2026-02-01');
    await create(price: 1100, validFrom: '2027-01-01');
    await create(price: 1200, validFrom: '2026-10-01');

    final list = await sut.watchForCustomer('c-1', today: today).first;

    expect(list.map((a) => a.unitPrice), [1200, 1100, 1000]);
    expect(list.map((a) => a.status), [
      AgreementStatus.inForce,
      AgreementStatus.future,
      AgreementStatus.ended,
    ]);
    expect(list.first.productName, 'Agua 20L');
    expect(list.first.isSynced, isFalse);
  });
}
