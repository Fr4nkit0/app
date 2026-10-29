import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_agreement.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer_agreement.repository.dart';
import 'package:app/features/customers/domain/usecases/create_customer_agreement.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// Stores the agreement and queues it, then fails.
class _FailingAfterWriteRepository extends DriftCustomerAgreementRepository {
  _FailingAfterWriteRepository(super.db);

  @override
  Future<String> create({
    required String customerId,
    required String productId,
    required double unitPrice,
    required String validFrom,
    String? validTo,
    String? reason,
  }) async {
    await super.create(
      customerId: customerId,
      productId: productId,
      unitPrice: unitPrice,
      validFrom: validFrom,
      validTo: validTo,
      reason: reason,
    );
    throw Exception('disk full');
  }
}

void main() {
  late AppDatabase db;

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

  CreateCustomerAgreementUseCase useCase([CustomerAgreementRepository? repo]) =>
      CreateCustomerAgreementUseCase(
        agreementRepo: repo ?? DriftCustomerAgreementRepository(db),
        transaction: driftTransactionRunner(db),
      );

  Future<String> create(
    CreateCustomerAgreementUseCase sut, {
    double price = 1200,
    String validFrom = '2026-10-22',
    String? validTo,
    String? reason,
  }) => sut.execute(
    customerId: 'c-1',
    productId: 'p-1',
    unitPrice: price,
    validFrom: validFrom,
    validTo: validTo,
    reason: reason,
  );

  Future<void> expectNothingStored() async {
    expect(await db.select(db.customerAgreementTable).get(), isEmpty);
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
  }

  test('stores the agreement with a trimmed reason and queues it', () async {
    final id = await create(useCase(), reason: '  Cliente mayorista  ');

    final row = await db.select(db.customerAgreementTable).getSingle();
    expect(row.agreementId, id);
    expect(row.unitPrice, 1200);
    expect(row.reason, 'Cliente mayorista');
    final change = (await DriftPendingChangeRepository(db).getPending()).single;
    expect(change.entity, PendingEntity.customerAgreement);
    expect(change.action, PendingAction.insert);
    expect(change.entityId, id);
  });

  test('a blank reason is stored as none', () async {
    await create(useCase(), reason: '   ');

    expect(
      (await db.select(db.customerAgreementTable).getSingle()).reason,
      isNull,
    );
  });

  for (final (name, invalid, message)
      in <
        (
          String,
          Future<String> Function(CreateCustomerAgreementUseCase),
          String,
        )
      >[
        (
          'a price of 0',
          (s) => create(s, price: 0),
          'El precio debe ser mayor a 0.',
        ),
        (
          'a price with 3 decimals',
          (s) => create(s, price: 12.345),
          'El precio admite hasta 2 decimales.',
        ),
        (
          'an end before the start',
          (s) => create(s, validFrom: '2026-10-22', validTo: '2026-10-21'),
          'La fecha de fin no puede ser anterior al inicio.',
        ),
        (
          'a reason over the limit',
          (s) => create(s, reason: 'x' * 501),
          'El motivo admite hasta 500 caracteres.',
        ),
      ]) {
    test('$name throws a ValidationFailure and stores nothing', () async {
      await expectLater(
        invalid(useCase()),
        throwsA(
          isA<ValidationFailure>().having((f) => f.message, 'message', message),
        ),
      );
      await expectNothingStored();
    });
  }

  test('a failing write leaves no agreement and no pending change', () async {
    await expectLater(
      create(useCase(_FailingAfterWriteRepository(db))),
      throwsA(isA<StorageFailure>()),
    );
    await expectNothingStored();
  });
}
