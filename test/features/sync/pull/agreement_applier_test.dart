import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/pull/agreement_applier.dart';

import 'pull_support.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = memoryDatabase();
    await seedCustomer(db, id: 'cust-1', serverId: 11);
    await seedProduct(db, id: 'prod-1', serverId: 21);
  });
  tearDown(() => db.close());

  Map<String, dynamic> agreement({
    required int id,
    String? clientUuid,
    int customerId = 11,
    int productId = 21,
    double price = 900,
  }) => {
    'id': id,
    'client_uuid': clientUuid,
    'customer_id': customerId,
    'product_id': productId,
    'unit_price': '$price',
    'valid_from': '2026-10-01',
    'valid_to': null,
    'reason': null,
  };

  Future<void> seedAgreement(String id, {int? serverId}) => db
      .into(db.customerAgreementTable)
      .insert(
        CustomerAgreementTableCompanion.insert(
          agreementId: Value(id),
          customerId: 'cust-1',
          productId: 'prod-1',
          unitPrice: 800,
          validFrom: '2026-09-01',
          serverId: Value(serverId),
        ),
      );

  group('pull', () {
    test(
      'matches an agreement pushed by the device by its client uuid',
      () async {
        await seedAgreement('agr-uuid');

        await AgreementApplier(db).applyChanges({
          'customer_agreements': [agreement(id: 300, clientUuid: 'agr-uuid')],
        }, await pullContext(db));

        final row = await db.select(db.customerAgreementTable).getSingle();
        expect(row.agreementId, 'agr-uuid');
        expect(row.serverId, 300);
        expect(row.unitPrice, 900);
      },
    );

    test(
      'skips an agreement whose customer or product is not on the device',
      () async {
        await AgreementApplier(db).applyChanges({
          'customer_agreements': [
            agreement(id: 301, customerId: 99),
            agreement(id: 302, productId: 99),
          ],
        }, await pullContext(db));

        expect(await db.select(db.customerAgreementTable).get(), isEmpty);
      },
    );
  });

  group('bootstrap', () {
    test(
      'replaces the server agreements and keeps the ones only on the device',
      () async {
        await seedAgreement('agr-stale', serverId: 200);
        await seedAgreement('agr-pushed', serverId: 201);
        await seedAgreement('agr-local');
        final context = await bootstrapContext(db);
        context.ids.recordProduct(21, 'prod-1');

        await AgreementApplier(db).replaceForCustomer('cust-1', [
          agreement(id: 201, clientUuid: 'agr-pushed', price: 950),
          agreement(id: 202),
        ], context);

        final rows = await db.select(db.customerAgreementTable).get();
        expect(rows.map((r) => r.serverId), unorderedEquals([201, 202, null]));
        expect(
          rows.firstWhere((r) => r.serverId == 201).agreementId,
          'agr-pushed',
        );
        expect(rows.firstWhere((r) => r.serverId == 201).unitPrice, 950);
      },
    );

    test(
      'skips an agreement whose product is not in the same download',
      () async {
        await AgreementApplier(db).replaceForCustomer('cust-1', [
          agreement(id: 202),
        ], await bootstrapContext(db));

        expect(await db.select(db.customerAgreementTable).get(), isEmpty);
      },
    );
  });
}
