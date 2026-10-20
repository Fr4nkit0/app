import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  test('bootstrap never empties the pending queue', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final queue = DriftPendingChangeRepository(db);
    await queue.enqueue(
      entity: PendingEntity.sale,
      entityId: 'sale-1',
      action: PendingAction.insert,
    );
    await queue.enqueue(
      entity: PendingEntity.customer,
      entityId: 'cust-1',
      action: PendingAction.insert,
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json(200, {
          'data': {
            'customers': [
              {'id': 1, 'name': 'Server Customer', 'phone_number': '123'},
            ],
            'products': [
              {'id': 2, 'name': 'Water 20L', 'price': 1500},
            ],
          },
        }),
      );

    await SyncService(dio, db).bootstrap();

    final ids = (await queue.getPending()).map((c) => c.entityId);
    expect(ids, ['sale-1', 'cust-1']);
  });
}
