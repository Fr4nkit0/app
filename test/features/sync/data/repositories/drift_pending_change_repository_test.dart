import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

void main() {
  late AppDatabase db;
  late DriftPendingChangeRepository sut;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftPendingChangeRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> enqueueSale(String id) => sut.enqueue(
    entity: PendingEntity.sale,
    entityId: id,
    action: PendingAction.insert,
    payload: {'saleId': id},
  );

  group('enqueue', () {
    test('stores entity, uuid, action and payload as pending', () async {
      await sut.enqueue(
        entity: PendingEntity.payment,
        entityId: 'pay-1',
        action: PendingAction.insert,
        payload: {'amount': 500},
      );

      final change = (await sut.getPending()).single;
      expect(change.entity, PendingEntity.payment);
      expect(change.entityId, 'pay-1');
      expect(change.action, PendingAction.insert);
      expect(change.payload, {'amount': 500});
      expect(change.status, PendingStatus.pending);
      expect(change.rejectionReason, isNull);
    });

    test('accepts a change without payload', () async {
      await sut.enqueue(
        entity: PendingEntity.customer,
        entityId: 'cust-1',
        action: PendingAction.delete,
      );

      expect((await sut.getPending()).single.payload, isNull);
    });
  });

  group('ordering', () {
    test('returns pending changes in creation order', () async {
      for (final id in ['a', 'b', 'c', 'd']) {
        await enqueueSale(id);
      }

      final ids = (await sut.getPending()).map((c) => c.entityId);
      expect(ids, ['a', 'b', 'c', 'd']);
    });

    test('keeps one entry per mutation of the same record', () async {
      await sut.enqueue(
        entity: PendingEntity.customer,
        entityId: 'cust-1',
        action: PendingAction.insert,
      );
      await sut.enqueue(
        entity: PendingEntity.customer,
        entityId: 'cust-1',
        action: PendingAction.update,
      );

      final actions = (await sut.getPending()).map((c) => c.action);
      expect(actions, [PendingAction.insert, PendingAction.update]);
    });
  });

  group('transitions', () {
    test('markSent removes the change from the pending list', () async {
      await enqueueSale('a');
      await enqueueSale('b');
      final first = (await sut.getPending()).first;

      await sut.markSent([first.id]);

      expect((await sut.getPending()).map((c) => c.entityId), ['b']);
      expect(await sut.countPending(), 1);
    });

    test('markSent records the sent status', () async {
      await enqueueSale('a');
      final id = (await sut.getPending()).single.id;

      await sut.markSent([id]);

      final row = await db.select(db.pendingChangeTable).getSingle();
      expect(row.status, 'sent');
    });

    test(
      'markRejected stores the reason and leaves the pending list',
      () async {
        await enqueueSale('a');
        final id = (await sut.getPending()).single.id;

        await sut.markRejected(id, 'Product no longer exists');

        expect(await sut.getPending(), isEmpty);
        final rejected = await sut.getRejected();
        expect(rejected.single.status, PendingStatus.rejected);
        expect(rejected.single.rejectionReason, 'Product no longer exists');
      },
    );

    test('a sent change cannot be rejected afterwards', () async {
      await enqueueSale('a');
      final id = (await sut.getPending()).single.id;
      await sut.markSent([id]);

      await sut.markRejected(id, 'too late');

      expect(await sut.getRejected(), isEmpty);
      final row = await db.select(db.pendingChangeTable).getSingle();
      expect(row.status, 'sent');
    });

    test('a rejected change cannot be marked as sent afterwards', () async {
      await enqueueSale('a');
      final id = (await sut.getPending()).single.id;
      await sut.markRejected(id, 'invalid');

      await sut.markSent([id]);

      final row = await db.select(db.pendingChangeTable).getSingle();
      expect(row.status, 'rejected');
    });

    test('markSent with an empty list is a no-op', () async {
      await enqueueSale('a');

      await sut.markSent(const []);

      expect(await sut.countPending(), 1);
    });
  });

  group('counting', () {
    test('countPending ignores sent and rejected changes', () async {
      await enqueueSale('a');
      await enqueueSale('b');
      await enqueueSale('c');
      final changes = await sut.getPending();
      await sut.markSent([changes[0].id]);
      await sut.markRejected(changes[1].id, 'invalid');

      expect(await sut.countPending(), 1);
    });

    test('watchPendingCount emits as the queue changes', () async {
      final emissions = <int>[];
      final sub = sut.watchPendingCount().listen(emissions.add);
      await pumpEventQueue();

      await enqueueSale('a');
      await pumpEventQueue();
      await sut.markSent([(await sut.getPending()).single.id]);
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions, [0, 1, 0]);
    });
  });

  group('watchLatestFor', () {
    test('yields null when the record has no queue row', () async {
      await enqueueSale('other');

      final latest = await sut.watchLatestFor(PendingEntity.sale, 'a').first;

      expect(latest, isNull);
    });

    test('yields the pending row of the record', () async {
      await enqueueSale('a');

      final latest = await sut.watchLatestFor(PendingEntity.sale, 'a').first;

      expect(latest?.entityId, 'a');
      expect(latest?.status, PendingStatus.pending);
    });

    test('does not mix entities that share an id', () async {
      await enqueueSale('a');

      final latest = await sut
          .watchLatestFor(PendingEntity.routeStop, 'a')
          .first;

      expect(latest, isNull);
    });

    test('yields sent and rejected states with the reason', () async {
      await enqueueSale('a');
      await enqueueSale('b');
      final pending = await sut.getPending();
      await sut.markSent([pending.first.id]);
      await sut.markRejected(pending.last.id, 'Cliente dado de baja');

      final sent = await sut.watchLatestFor(PendingEntity.sale, 'a').first;
      final rejected = await sut.watchLatestFor(PendingEntity.sale, 'b').first;

      expect(sent?.status, PendingStatus.sent);
      expect(rejected?.status, PendingStatus.rejected);
      expect(rejected?.rejectionReason, 'Cliente dado de baja');
    });

    test('a later row wins and the stream emits as it arrives', () async {
      await enqueueSale('a');
      await sut.markSent([(await sut.getPending()).single.id]);
      final emissions = <PendingStatus?>[];
      final sub = sut
          .watchLatestFor(PendingEntity.sale, 'a')
          .listen((c) => emissions.add(c?.status));
      await pumpEventQueue();

      await enqueueSale('a');
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions, [PendingStatus.sent, PendingStatus.pending]);
    });
  });
}
