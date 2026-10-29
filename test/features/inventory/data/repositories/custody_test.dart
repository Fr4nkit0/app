import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/inventory/data/repositories/custody.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';

void main() {
  late AppDatabase db;
  late Custody custody;
  late PendingChangeRepository queue;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    custody = Custody(db);
    queue = DriftPendingChangeRepository(db);
    for (final id in ['ana', 'beto']) {
      await db
          .into(db.customerTable)
          .insert(
            CustomerTableCompanion.insert(customerId: Value(id), name: id),
          );
    }
  });

  tearDown(() => db.close());

  /// Records a movement the way the app does: the row, its custody effect
  /// and its pending change.
  Future<void> movement(
    String id, {
    String customerId = 'ana',
    String code = 'BIDON_20L',
    int delivered = 0,
    int returned = 0,
  }) => DriftInventoryRepository(db).recordContainerMovement(
    ContainerMovement(
      id: id,
      customerId: customerId,
      containerType: code,
      deliveredQuantity: delivered,
      returnedQuantity: returned,
      createdAt: DateTime(2026, 10, 19, 10),
    ),
  );

  Future<int?> held(String customerId, String code) async =>
      (await custody.watch(customerId).first)
          .where((b) => b.containerType == code)
          .firstOrNull
          ?.quantity;

  group('post', () {
    test('opens the custody of a code the customer did not hold', () async {
      await custody.post('ana', 'BIDON_20L', 3);

      expect(await held('ana', 'BIDON_20L'), 3);
    });

    test('moves the custody of a code by the delta', () async {
      await custody.post('ana', 'BIDON_20L', 3);
      await custody.post('ana', 'BIDON_20L', -1);

      expect(await held('ana', 'BIDON_20L'), 2);
    });
  });

  test('watch lists the custody of the customer per code', () async {
    await custody.post('ana', 'BIDON_20L', 3);
    await custody.post('ana', 'SIFON_2L', 1);
    await custody.post('beto', 'BIDON_20L', 9);

    final balances = await custody.watch('ana').first;

    expect(
      {for (final b in balances) b.containerType: b.quantity},
      {'BIDON_20L': 3, 'SIFON_2L': 1},
    );
  });

  group('pendingMovements', () {
    test('nets the unsent movements of the customer and code', () async {
      await movement('m1', delivered: 3, returned: 1);
      await movement('m2', returned: 1);

      expect(await custody.pendingMovements('ana', 'BIDON_20L'), 1);
    });

    test('ignores other customers and other codes', () async {
      await movement('m1', delivered: 3);
      await movement('m2', customerId: 'beto', delivered: 5);
      await movement('m3', code: 'SIFON_2L', delivered: 7);

      expect(await custody.pendingMovements('ana', 'BIDON_20L'), 3);
    });

    test('ignores sent and rejected movements', () async {
      await movement('m-sent', delivered: 2);
      await movement('m-rejected', delivered: 4);
      final [sent, rejected] = await queue.getPending();
      await queue.markSent([sent.id]);
      await queue.markRejected(rejected.id, 'invalid');

      expect(await custody.pendingMovements('ana', 'BIDON_20L'), 0);
    });
  });

  group('reconcile', () {
    test('without pending movements stores the server value', () async {
      await custody.post('ana', 'BIDON_20L', 9);

      await custody.reconcile('ana', 'BIDON_20L', 7);

      expect(await held('ana', 'BIDON_20L'), 7);
    });

    test('adds the pending movements to the server value', () async {
      await movement('m1', delivered: 3, returned: 1);

      await custody.reconcile('ana', 'BIDON_20L', 7);

      expect(await held('ana', 'BIDON_20L'), 7 + 2);
    });

    test(
      'a rejected movement is no longer pending: the server value',
      () async {
        await movement('m1', delivered: 3);
        await queue.markRejected(
          (await queue.getPending()).single.id,
          'invalid',
        );

        await custody.reconcile('ana', 'BIDON_20L', 7);

        expect(await held('ana', 'BIDON_20L'), 7);
      },
    );

    test('stores the server id and enabled flag when given', () async {
      await custody.reconcile(
        'ana',
        'BIDON_20L',
        7,
        serverId: 1300,
        enabled: const Value(false),
      );

      final row = await db.select(db.customerContainerBalanceTable).getSingle();
      expect(row.serverId, 1300);
      expect(row.enabled, isFalse);
    });
  });
}
