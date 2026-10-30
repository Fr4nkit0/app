import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';
import 'package:app/features/visits/data/repositories/drift_visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';
import 'package:app/features/visits/domain/usecases/edit_visit.usecase.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

void main() {
  late AppDatabase db;
  late SyncEngine engine;
  late PendingChangeRepository queue;
  late List<Json> pushBodies;
  late Json? Function(Json record)? answer;

  final arrivedAt = DateTime(2026, 10, 29, 10);
  final editedAt = DateTime(2026, 10, 29, 11, 30);

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
            'visits': [
              for (final r in (body['visits'] as List? ?? const []))
                answer?.call(Map<String, dynamic>.from(r as Map)) ??
                    {
                      'uuid': (r as Map)['uuid'],
                      'status': 'accepted',
                      'server_id': ++nextId,
                      'review_reason': null,
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
    for (final (id, name) in [(1, 'Ausente'), (2, 'No quiso')]) {
      await db
          .into(db.visitOutcomeTable)
          .insert(
            VisitOutcomeTableCompanion.insert(id: drift.Value(id), name: name),
          );
    }
    await DriftVisitRepository(db).recordVisit(
      Visit(
        visitId: 'v-1',
        routeStopId: 's-1',
        customerId: 'c-1',
        visitType: VisitType.visit,
        outcomeId: 2,
        arrivedAt: arrivedAt,
        observations: 'Tocar timbre',
      ),
    );
  });
  tearDown(() => db.close());

  Future<void> edit({required int outcomeId, String? notes}) =>
      EditVisitUseCase(
        visitRepo: DriftVisitRepository(db),
        transaction: driftTransactionRunner(db),
        now: () => editedAt,
      ).execute(visitId: 'v-1', outcomeId: outcomeId, notes: notes);

  List<Json> visitsIn(Json body) => [
    for (final r in body['visits'] as List) Map<String, dynamic>.from(r as Map),
  ];

  test('an edited visit already sent travels again with the same uuid, the new '
      'outcome and notes and a later modified_at', () async {
    await engine.push();
    final created = visitsIn(pushBodies.single).single;
    expect(created.containsKey('modified_at'), isFalse);

    await edit(outcomeId: 1, notes: 'No estaba');
    await engine.push();

    final edited = visitsIn(pushBodies.last).single;
    expect(edited['uuid'], 'v-1');
    expect(edited['outcome_id'], 1);
    expect(edited['notes'], 'No estaba');
    expect(edited['modified_at'], editedAt.toUtc().toIso8601String());
    expect(
      DateTime.parse(edited['modified_at'] as String).isAfter(arrivedAt),
      isTrue,
    );
    expect(await queue.countPending(), 0);
  });

  test(
    'a never-sent edited visit travels once with the latest values',
    () async {
      await edit(outcomeId: 1);

      await engine.push();

      final sent = visitsIn(pushBodies.single);
      expect(sent, hasLength(1));
      expect(sent.single['uuid'], 'v-1');
      expect(sent.single['outcome_id'], 1);
      expect(sent.single['notes'], isNull);
      expect(sent.single['modified_at'], editedAt.toUtc().toIso8601String());
      expect(await queue.countPending(), 0);
    },
  );

  test('an edit the server refuses stays rejected with its reason', () async {
    await engine.push();
    await edit(outcomeId: 1);
    answer = (r) => {
      'uuid': r['uuid'],
      'status': 'rejected',
      'server_id': null,
      'review_reason': null,
      'error': "Only today's visits can be edited.",
    };

    await engine.push();

    final rejected = await queue.getRejected();
    expect(rejected.single.entityId, 'v-1');
    expect(
      rejected.single.rejectionReason,
      "Only today's visits can be edited.",
    );
  });
}
