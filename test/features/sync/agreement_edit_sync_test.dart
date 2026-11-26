import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/data/repositories/server_shadow.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

/// Edits, closes and soft deletes of agreements going up (S6): the record
/// carries the server id, enabled and modified_at, and the server's
/// outdated or rejected answers put the server's values back.
void main() {
  late AppDatabase db;
  late SyncEngine engine;
  late PendingChangeRepository queue;
  late List<Json> pushBodies;
  late Json? Function(Json record)? answer;

  final edited = DateTime.utc(2026, 11, 26, 15, 30);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    pushBodies = [];
    answer = null;
    var nextId = 900;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter((options) async {
        final body = Map<String, dynamic>.from(options.data as Map);
        pushBodies.add(body);
        return FakeHttpAdapter.json(200, {
          'data': {
            for (final MapEntry(key: entity, value: records) in body.entries)
              entity: [
                for (final r in records as List)
                  answer?.call(Map<String, dynamic>.from(r as Map)) ??
                      {
                        'uuid': (r as Map)['uuid'],
                        'status': 'accepted',
                        'server_id': r['server_id'] ?? ++nextId,
                      },
              ],
          },
          'message': null,
        });
      });
    engine = SyncEngine(dio: dio, db: db, sync: SyncService(dio, db));
    queue = DriftPendingChangeRepository(db);

    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
            serverId: const drift.Value(10),
          ),
        );
    await db
        .into(db.productTable)
        .insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('p-1'),
            name: 'Agua 20L',
            price: 1500,
            serverId: const drift.Value(21),
          ),
        );
    await db
        .into(db.customerAgreementTable)
        .insert(
          CustomerAgreementTableCompanion.insert(
            agreementId: const drift.Value('agr-1'),
            customerId: 'c-1',
            productId: 'p-1',
            unitPrice: 900,
            validFrom: '2026-10-01',
            reason: const drift.Value('Mayorista'),
            serverId: const drift.Value(500),
          ),
        );
  });
  tearDown(() => db.close());

  /// A local write of agreement [id], as the repository does it: the server
  /// values are kept first, then the row changes and its update is queued.
  Future<void> editLocally(
    String id,
    CustomerAgreementTableCompanion fields, {
    PendingAction action = PendingAction.update,
  }) async {
    await ServerShadow(db).captureBeforeEdit(PendingEntity.customerAgreement, id);
    await (db.update(db.customerAgreementTable)
          ..where((t) => t.agreementId.equals(id)))
        .write(fields.copyWith(lastModifiedDate: drift.Value(edited)));
    await queue.enqueue(
      entity: PendingEntity.customerAgreement,
      entityId: id,
      action: action,
    );
  }

  Future<CustomerAgreementTableData> row(String id) =>
      (db.select(db.customerAgreementTable)
            ..where((t) => t.agreementId.equals(id)))
          .getSingle();

  Json serverRow({double price = 900, bool enabled = true}) => {
    'id': 500,
    'client_uuid': 'agr-1',
    'customer_id': 10,
    'product_id': 21,
    'unit_price': price.toStringAsFixed(2),
    'valid_from': '2026-10-01',
    'valid_to': null,
    'reason': 'Mayorista',
    'enabled': enabled,
  };

  test('an edit of a synced agreement sends the whole record with server_id, '
      'enabled and modified_at', () async {
    await editLocally(
      'agr-1',
      const CustomerAgreementTableCompanion(
        validTo: drift.Value('2026-12-31'),
        reason: drift.Value('Fin de temporada'),
      ),
    );

    await engine.push();

    expect(pushBodies.single['customer_agreements'], [
      {
        'uuid': 'agr-1',
        'server_id': 500,
        'customer_id': 10,
        'product_id': 21,
        'unit_price': 900.0,
        'valid_from': '2026-10-01',
        'valid_to': '2026-12-31',
        'reason': 'Fin de temporada',
        'enabled': true,
        'modified_at': '2026-11-26T15:30:00.000Z',
      },
    ]);
    expect(await queue.getPending(), isEmpty);
    expect((await row('agr-1')).serverId, 500);
  });

  test('a soft delete sends enabled false', () async {
    await editLocally(
      'agr-1',
      const CustomerAgreementTableCompanion(enabled: drift.Value(false)),
    );

    await engine.push();

    final record =
        (pushBodies.single['customer_agreements'] as List).single as Map;
    expect(record['enabled'], isFalse);
    expect(record['server_id'], 500);
  });

  test('a replacement sends the close of the old one before the new one, '
      'even when the new one sorts first by uuid', () async {
    await editLocally(
      'agr-1',
      const CustomerAgreementTableCompanion(validTo: drift.Value('2026-11-25')),
    );
    await db
        .into(db.customerAgreementTable)
        .insert(
          CustomerAgreementTableCompanion.insert(
            agreementId: const drift.Value('agr-0-new'),
            customerId: 'c-1',
            productId: 'p-1',
            unitPrice: 950,
            validFrom: '2026-11-26',
            lastModifiedDate: drift.Value(edited),
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.customerAgreement,
      entityId: 'agr-0-new',
      action: PendingAction.insert,
    );
    // A later change of the old one does not move it behind the new one.
    await queue.enqueue(
      entity: PendingEntity.customerAgreement,
      entityId: 'agr-1',
      action: PendingAction.update,
    );

    await engine.push();

    final records = pushBodies.single['customer_agreements'] as List;
    expect([for (final r in records) (r as Map)['uuid']], [
      'agr-1',
      'agr-0-new',
    ]);
    expect((records[0] as Map)['valid_to'], '2026-11-25');
    expect((records[1] as Map).containsKey('server_id'), isFalse);
    expect((records[1] as Map)['enabled'], isTrue);
    expect((await row('agr-0-new')).serverId, isNotNull);
  });

  test('outdated with current replaces the local copy with the server '
      'row', () async {
    await editLocally(
      'agr-1',
      const CustomerAgreementTableCompanion(reason: drift.Value('Local')),
    );
    answer = (r) => {
      'uuid': r['uuid'],
      'status': 'outdated',
      'server_id': 500,
      'current': {
        ...serverRow(price: 1100),
        'valid_to': '2026-12-15',
        'reason': 'Servidor',
      },
    };

    await engine.push();

    final local = await row('agr-1');
    expect(local.unitPrice, 1100);
    expect(local.validTo, '2026-12-15');
    expect(local.reason, 'Servidor');
    expect(local.enabled, isTrue);
    expect(await queue.getPending(), isEmpty);
  });

  test('outdated without current restores the values kept before the '
      'edit', () async {
    await editLocally(
      'agr-1',
      const CustomerAgreementTableCompanion(reason: drift.Value('Local')),
    );
    answer = (r) => {
      'uuid': r['uuid'],
      'status': 'outdated',
      'server_id': 500,
    };

    await engine.push();

    expect((await row('agr-1')).reason, 'Mayorista');
  });

  test('a rejected edit rolls the row back to the server values and records '
      'what was refused', () async {
    const reason =
        'El precio y el inicio de un acuerdo que ya usaron ventas no se '
        'pueden cambiar: finalizalo y creá uno nuevo.';
    await editLocally(
      'agr-1',
      const CustomerAgreementTableCompanion(
        unitPrice: drift.Value(950),
        validFrom: drift.Value('2026-11-26'),
      ),
    );
    answer = (r) => {'uuid': r['uuid'], 'status': 'rejected', 'error': reason};

    await engine.push();

    final local = await row('agr-1');
    expect(local.unitPrice, 900);
    expect(local.validFrom, '2026-10-01');
    expect(local.reason, 'Mayorista');
    final rejected = (await queue.getRejected()).single;
    expect(rejected.rejectionReason, reason);
    expect(rejected.payload?[PendingChange.rollbackKey], 'restored');
    expect(rejected.payload?[PendingChange.rejectedValuesKey], {
      'unit_price': 950.0,
      'valid_from': '2026-11-26',
      'valid_to': null,
      'reason': 'Mayorista',
      'enabled': true,
    });
  });

  test('a rejected soft delete brings the agreement back with the server '
      'row the answer carries', () async {
    await editLocally(
      'agr-1',
      const CustomerAgreementTableCompanion(enabled: drift.Value(false)),
    );
    answer = (r) => {
      'uuid': r['uuid'],
      'status': 'rejected',
      'error': 'No.',
      'current': serverRow(price: 990),
    };

    await engine.push();

    final local = await row('agr-1');
    expect(local.enabled, isTrue);
    expect(local.unitPrice, 990);
  });

  test('a rejected new agreement the server never stored is deleted', () async {
    await db
        .into(db.customerAgreementTable)
        .insert(
          CustomerAgreementTableCompanion.insert(
            agreementId: const drift.Value('agr-new'),
            customerId: 'c-1',
            productId: 'p-1',
            unitPrice: 950,
            validFrom: '2026-11-26',
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.customerAgreement,
      entityId: 'agr-new',
      action: PendingAction.insert,
    );
    answer = (r) => {'uuid': r['uuid'], 'status': 'rejected', 'error': 'No.'};

    await engine.push();

    final rows = await (db.select(
      db.customerAgreementTable,
    )..where((t) => t.agreementId.equals('agr-new'))).get();
    expect(rows, isEmpty);
    expect(
      (await queue.getRejected()).single.payload?[PendingChange.rollbackKey],
      'deleted',
    );
  });

  test('a rejected new agreement a sale already used is kept', () async {
    await db
        .into(db.customerAgreementTable)
        .insert(
          CustomerAgreementTableCompanion.insert(
            agreementId: const drift.Value('agr-new'),
            customerId: 'c-1',
            productId: 'p-1',
            unitPrice: 950,
            validFrom: '2026-11-26',
          ),
        );
    await db
        .into(db.saleTable)
        .insert(
          SaleTableCompanion.insert(
            saleId: const drift.Value('s-1'),
            customerId: 'c-1',
            totalAmount: 950,
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
            unitPrice: 950,
            subtotal: 950,
            agreementUuid: const drift.Value('agr-new'),
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.customerAgreement,
      entityId: 'agr-new',
      action: PendingAction.insert,
    );
    answer = (r) => {'uuid': r['uuid'], 'status': 'rejected', 'error': 'No.'};

    await engine.push();

    expect((await row('agr-new')).unitPrice, 950);
    expect(
      (await queue.getRejected()).single.payload?[PendingChange.rollbackKey],
      'kept',
    );
  });

  test('the kept server values are forgotten once the edit is sent', () async {
    await editLocally(
      'agr-1',
      const CustomerAgreementTableCompanion(reason: drift.Value('Local')),
    );
    expect(
      await ServerShadow(db).read(PendingEntity.customerAgreement, 'agr-1'),
      {
        'unit_price': 900.0,
        'valid_from': '2026-10-01',
        'valid_to': null,
        'reason': 'Mayorista',
        'enabled': true,
      },
    );

    await engine.push();

    expect(
      await ServerShadow(db).read(PendingEntity.customerAgreement, 'agr-1'),
      isNull,
    );
  });
}
