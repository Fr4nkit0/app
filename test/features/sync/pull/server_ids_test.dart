import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/pull/server_ids.dart';

import 'pull_support.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = memoryDatabase();
    await seedCustomer(db, id: 'cust-stored', serverId: 11);
  });
  tearDown(() => db.close());

  test('stored ids resolve any row on the device by its server id', () async {
    final ids = ServerIds.stored(db);

    expect(await ids.customer(11), 'cust-stored');
    expect(await ids.customer(99), isNull);
    expect(await ids.customer(null), isNull);
  });

  test(
    'downloaded ids resolve only rows recorded in the same download',
    () async {
      final ids = ServerIds.downloaded(db);

      expect(await ids.customer(11), isNull);

      ids.recordCustomer(11, 'cust-stored');
      expect(await ids.customer(11), 'cust-stored');
    },
  );
}
