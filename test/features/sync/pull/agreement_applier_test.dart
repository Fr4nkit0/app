import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/server_shadow.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
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
    bool? enabled,
  }) => {
    'id': id,
    'client_uuid': clientUuid,
    'customer_id': customerId,
    'product_id': productId,
    'unit_price': '$price',
    'valid_from': '2026-10-01',
    'valid_to': null,
    'reason': null,
    'enabled': ?enabled,
  };

  Future<CustomerAgreementTableData> rowOf(String id) => (db.select(
    db.customerAgreementTable,
  )..where((t) => t.agreementId.equals(id))).getSingle();

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

    test('stores a disabled agreement as disabled', () async {
      await seedAgreement('agr-1', serverId: 300);

      await AgreementApplier(db).applyChanges({
        'customer_agreements': [
          agreement(id: 300, enabled: false),
          agreement(id: 301, clientUuid: 'agr-new', enabled: false),
        ],
      }, await pullContext(db));

      expect((await rowOf('agr-1')).enabled, isFalse);
      expect((await rowOf('agr-new')).enabled, isFalse);
    });

    test('a row without enabled leaves the stored flag as it is', () async {
      await seedAgreement('agr-1', serverId: 300);
      await (db.update(db.customerAgreementTable)
            ..where((t) => t.agreementId.equals('agr-1')))
          .write(const CustomerAgreementTableCompanion(enabled: Value(false)));

      await AgreementApplier(db).applyChanges({
        'customer_agreements': [agreement(id: 300, price: 950)],
      }, await pullContext(db));

      final row = await rowOf('agr-1');
      expect(row.enabled, isFalse);
      expect(row.unitPrice, 950);
    });

    test('keeps an agreement with an unsent change and its server copy for '
        'a rollback', () async {
      await seedAgreement('agr-1', serverId: 300);
      await enqueueUnsent(db, PendingEntity.customerAgreement, 'agr-1');

      await AgreementApplier(db).applyChanges({
        'customer_agreements': [
          agreement(id: 300, clientUuid: 'agr-1', price: 990, enabled: false),
        ],
      }, await pullContext(db));

      final row = await rowOf('agr-1');
      expect(row.unitPrice, 800);
      expect(row.enabled, isTrue);
      expect(
        await ServerShadow(db).read(PendingEntity.customerAgreement, 'agr-1'),
        {
          'unit_price': 990.0,
          'valid_from': '2026-10-01',
          'valid_to': null,
          'reason': null,
          'enabled': false,
        },
      );
    });
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


    test('stores enabled and keeps an agreement with an unsent change, even '
        'one the download no longer carries', () async {
      await seedAgreement('agr-edited', serverId: 201);
      await seedAgreement('agr-closed', serverId: 203);
      await enqueueUnsent(db, PendingEntity.customerAgreement, 'agr-edited');
      await enqueueUnsent(db, PendingEntity.customerAgreement, 'agr-closed');
      final context = await bootstrapContext(db);
      context.ids.recordProduct(21, 'prod-1');

      await AgreementApplier(db).replaceForCustomer('cust-1', [
        agreement(id: 201, clientUuid: 'agr-edited', price: 990, enabled: true),
        agreement(id: 202, enabled: true),
      ], context);

      final rows = await db.select(db.customerAgreementTable).get();
      expect(rows.map((r) => r.serverId), unorderedEquals([201, 202, 203]));
      expect((await rowOf('agr-edited')).unitPrice, 800);
      expect(rows.firstWhere((r) => r.serverId == 202).enabled, isTrue);
      expect(
        (await ServerShadow(
          db,
        ).read(PendingEntity.customerAgreement, 'agr-edited'))?['unit_price'],
        990.0,
      );
    });

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
