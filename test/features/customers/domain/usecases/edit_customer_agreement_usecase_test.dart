import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/drift.customer_agreement.repository.dart';
import 'package:app/features/customers/domain/usecases/delete_customer_agreement.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit_customer_agreement.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 10, 22, 9, 30);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
          ),
        );
    await db
        .into(db.productTable)
        .insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('p-1'),
            name: 'Agua 20L',
            price: 1500,
          ),
        );
  });
  tearDown(() => db.close());

  DriftCustomerAgreementRepository repo() =>
      DriftCustomerAgreementRepository(db, now: () => now);

  EditCustomerAgreementUseCase editUseCase() => EditCustomerAgreementUseCase(
    agreementRepo: repo(),
    transaction: driftTransactionRunner(db),
    now: () => now,
  );

  DeleteCustomerAgreementUseCase deleteUseCase() =>
      DeleteCustomerAgreementUseCase(
        agreementRepo: repo(),
        transaction: driftTransactionRunner(db),
      );

  Future<void> insert(
    String id, {
    int price = 1000,
    String from = '2026-10-01',
    String? to,
    String? reason,
    int? serverId = 7,
  }) => db
      .into(db.customerAgreementTable)
      .insert(
        CustomerAgreementTableCompanion.insert(
          agreementId: drift.Value(id),
          customerId: 'c-1',
          productId: 'p-1',
          unitPrice: price,
          validFrom: from,
          validTo: drift.Value(to),
          reason: drift.Value(reason),
          serverId: drift.Value(serverId),
        ),
      );

  Future<String> edit({
    String id = 'a-1',
    int price = 1000,
    String from = '2026-10-01',
    String? to,
    String? reason,
  }) => editUseCase().execute(
    agreementId: id,
    unitPrice: price,
    validFrom: from,
    validTo: to,
    reason: reason,
  );

  Future<List<CustomerAgreementTableData>> rows() =>
      db.select(db.customerAgreementTable).get();

  Future<List<PendingChange>> pending() =>
      DriftPendingChangeRepository(db).getPending();

  group('EditCustomerAgreementUseCase', () {
    test('a new price on a synced agreement in force replaces it', () async {
      await insert('a-1');

      final id = await edit(price: 1300);

      expect(id, isNot('a-1'));
      final all = {for (final r in await rows()) r.agreementId: r};
      expect(all['a-1']!.validTo, '2026-10-21');
      expect(all['a-1']!.unitPrice, 1000);
      expect(all[id]!.unitPrice, 1300);
      // Only future sales take the new price: the replacement starts today.
      expect(all[id]!.validFrom, '2026-10-22');
      expect((await pending()).map((c) => (c.entityId, c.action)), [
        ('a-1', PendingAction.update),
        (id, PendingAction.insert),
      ]);
    });

    test('a replacement keeps an edited start later than today', () async {
      await insert('a-1');

      final id = await edit(price: 1300, from: '2026-11-01');

      final all = {for (final r in await rows()) r.agreementId: r};
      expect(all[id]!.validFrom, '2026-11-01');
    });

    test('a replacement whose end is before today is refused and changes '
        'nothing', () async {
      await insert('a-1');

      await expectLater(
        edit(price: 1300, to: '2026-10-21'),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.message,
            'message',
            'La fecha de fin no puede ser anterior a hoy.',
          ),
        ),
      );

      final all = await rows();
      expect(all.map((r) => (r.agreementId, r.unitPrice, r.validTo)), [
        ('a-1', 1000, null),
      ]);
      expect(await pending(), isEmpty);
    });

    test('a new start on a synced agreement in force replaces it', () async {
      await insert('a-1');

      final id = await edit(from: '2026-10-22');

      expect(id, isNot('a-1'));
      expect(await rows(), hasLength(2));
    });

    test(
      'a synced agreement starting today is disabled when replaced',
      () async {
        await insert('a-1', from: '2026-10-22');

        final id = await edit(price: 1300, from: '2026-10-22');

        final all = {for (final r in await rows()) r.agreementId: r};
        expect(all['a-1']!.enabled, isFalse);
        expect(all[id]!.enabled, isTrue);
      },
    );

    test(
      'only the end and reason of one in force are edited in place',
      () async {
        await insert('a-1');

        final id = await edit(to: '2026-12-31', reason: '  Mayorista  ');

        expect(id, 'a-1');
        final row = (await rows()).single;
        expect(row.validTo, '2026-12-31');
        expect(row.reason, 'Mayorista');
        expect(row.unitPrice, 1000);
        final change = (await pending()).single;
        expect(change.entityId, 'a-1');
        expect(change.action, PendingAction.update);
      },
    );

    test('a future synced agreement is edited in place', () async {
      await insert('a-1', from: '2026-11-01');

      final id = await edit(price: 1300, from: '2026-11-15');

      expect(id, 'a-1');
      final row = (await rows()).single;
      expect(row.unitPrice, 1300);
      expect(row.validFrom, '2026-11-15');
    });

    test('an unsynced agreement in force is edited in place', () async {
      await insert('a-1', serverId: null);

      final id = await edit(price: 1300);

      expect(id, 'a-1');
      expect((await rows()).single.unitPrice, 1300);
    });

    test('a missing agreement throws NotFoundFailure', () async {
      await expectLater(edit(id: 'nope'), throwsA(isA<NotFoundFailure>()));
    });

    for (final (name, invalid, message)
        in <(String, Future<String> Function(), String)>[
          (
            'a price of 0',
            () => edit(price: 0),
            'El precio debe ser mayor a 0.',
          ),
          (
            'an end before the start',
            () => edit(from: '2026-10-22', to: '2026-10-21'),
            'La fecha de fin no puede ser anterior al inicio.',
          ),
          (
            'a reason over the limit',
            () => edit(reason: 'x' * 501),
            'El motivo admite hasta 500 caracteres.',
          ),
        ]) {
      test('$name throws a ValidationFailure and changes nothing', () async {
        await insert('a-1');

        await expectLater(
          invalid(),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.message,
              'message',
              message,
            ),
          ),
        );
        final row = (await rows()).single;
        expect(row.unitPrice, 1000);
        expect(row.validFrom, '2026-10-01');
        expect(row.validTo, isNull);
        expect(await pending(), isEmpty);
      });
    }
  });

  group('DeleteCustomerAgreementUseCase', () {
    test('a synced agreement is disabled and queued', () async {
      await insert('a-1');

      await deleteUseCase().execute('a-1');

      expect((await rows()).single.enabled, isFalse);
      final change = (await pending()).single;
      expect(change.entityId, 'a-1');
      expect(change.action, PendingAction.update);
    });

    test('an unsynced agreement a sale already used is disabled and stays '
        'queued, so the sale still references it on the server', () async {
      await insert('a-1', serverId: null);
      await DriftPendingChangeRepository(db).enqueue(
        entity: PendingEntity.customerAgreement,
        entityId: 'a-1',
        action: PendingAction.insert,
      );
      await db
          .into(db.saleTable)
          .insert(
            SaleTableCompanion.insert(
              saleId: const drift.Value('s-1'),
              customerId: 'c-1',
              totalAmount: 1000,
              paymentMethod: 'cash',
              quantity: 1,
              shipping_amount: 0,
            ),
          );
      await db
          .into(db.saleItemTable)
          .insert(
            SaleItemTableCompanion.insert(
              saleId: 's-1',
              productId: 'p-1',
              quantity: 1,
              unitPrice: 1000,
              subtotal: 1000,
              agreementUuid: const drift.Value('a-1'),
            ),
          );

      await deleteUseCase().execute('a-1');

      final row = (await rows()).single;
      expect((row.agreementId, row.enabled), ('a-1', false));
      expect((await pending()).map((c) => (c.entityId, c.action)), [
        ('a-1', PendingAction.insert),
        ('a-1', PendingAction.update),
      ]);
    });

    test('an unsynced agreement is removed with its pending insert', () async {
      final id = await repo().create(
        customerId: 'c-1',
        productId: 'p-1',
        unitPrice: 1200,
        validFrom: '2026-10-22',
      );

      await deleteUseCase().execute(id);

      expect(await rows(), isEmpty);
      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    });

    test('a missing agreement throws NotFoundFailure', () async {
      await expectLater(
        deleteUseCase().execute('nope'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });
}
