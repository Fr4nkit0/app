import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/models/truck_skeletons.dart';

const _today = '2026-11-25';
const _skeleton = 'ESQUELETO';

void main() {
  late AppDatabase db;
  late DriftInventoryRepository sut;
  var nextLoadId = 1;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftInventoryRepository(db);
    nextLoadId = 1;
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const Value('c-1'),
            name: 'Ana',
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> route(String id, {String date = _today}) async {
    await db
        .into(db.routeTable)
        .insert(
          RouteTableCompanion.insert(routeId: Value(id), route_date: date),
        );
    await db
        .into(db.routeStopTable)
        .insert(
          RouteStopTableCompanion.insert(
            routeStopId: Value('$id-stop'),
            routeId: id,
            customerId: 'c-1',
            sequence: 1,
            scheduledAt: DateTime(2026, 11, 25),
          ),
        );
  }

  Future<void> load(
    String routeId,
    int quantity, {
    String code = _skeleton,
    String type = 'load',
  }) => db
      .into(db.routeContainerLoadTable)
      .insert(
        RouteContainerLoadTableCompanion.insert(
          id: Value(nextLoadId++),
          routeId: routeId,
          containerType: code,
          quantity: quantity,
          type: type,
          loadedAt: DateTime(2026, 11, 25, 8),
        ),
      );

  Future<void> move(
    String id, {
    String? visitId,
    String? routeId,
    int delivered = 0,
    int returned = 0,
    String code = _skeleton,
    String? saleId,
  }) async {
    await sut.recordContainerMovement(
      ContainerMovement(
        id: id,
        customerId: 'c-1',
        containerType: code,
        deliveredQuantity: delivered,
        returnedQuantity: returned,
        createdAt: DateTime(2026, 11, 25, 10),
        visitId: visitId,
        routeId: routeId,
        saleId: saleId,
      ),
    );
  }

  Future<TruckSkeletons?> current() =>
      sut.watchTruckSkeletons(DateTime(2026, 11, 25, 9)).first;

  test('nothing without a route today', () async {
    await route('r-old', date: '2026-11-24');
    await load('r-old', 6);

    expect(await current(), isNull);
  });

  test("today's route without skeleton loads or movements is not "
      'tracked', () async {
    await route('r-1');
    await load('r-1', 4, code: 'BIDON_20L');

    expect(
      await current(),
      const TruckSkeletons(loaded: 0, remaining: 0, hasActivity: false),
    );
  });

  test('loaded sums the skeleton loads and corrections of the route; other '
      'types and days are left out', () async {
    await route('r-1');
    await route('r-old', date: '2026-11-24');
    await load('r-1', 6);
    await load('r-1', -1, type: 'correction');
    await load('r-1', 10, code: 'BIDON_20L');
    await load('r-old', 9);

    expect(
      await current(),
      const TruckSkeletons(loaded: 5, remaining: 5, hasActivity: true),
    );
  });

  test('remaining takes out what was delivered and adds what came back on '
      'the visits of the route', () async {
    await route('r-1');
    await route('r-old', date: '2026-11-24');
    await load('r-1', 6);
    await move('m-1', visitId: 'r-1-stop', delivered: 3, returned: 1);
    await move('m-2', routeId: 'r-1', delivered: 1);
    // Not this route's visits, or not skeletons.
    await move('m-3', visitId: 'r-old-stop', delivered: 5);
    await move('m-4', delivered: 5);
    await move('m-5', visitId: 'r-1-stop', delivered: 4, code: 'BIDON_20L');

    expect(
      await current(),
      const TruckSkeletons(loaded: 6, remaining: 3, hasActivity: true),
    );
  });

  test('a cancelled sale gives its skeletons back to the truck', () async {
    await route('r-1');
    await load('r-1', 6);
    await move('m-1', visitId: 'r-1-stop', delivered: 2, saleId: 's-1');
    expect((await current())!.remaining, 4);

    await sut.reverseSaleMovements('s-1', at: DateTime(2026, 11, 25, 11));

    expect((await current())!.remaining, 6);
  });

  test('remaining goes below zero when more was delivered than '
      'loaded', () async {
    await route('r-1');
    await load('r-1', 1);
    await move('m-1', visitId: 'r-1-stop', delivered: 3);

    expect(
      await current(),
      const TruckSkeletons(loaded: 1, remaining: -2, hasActivity: true),
    );
  });

  test('movements alone make the route tracked', () async {
    await route('r-1');
    await move('m-1', visitId: 'r-1-stop', returned: 2);

    expect(
      await current(),
      const TruckSkeletons(loaded: 0, remaining: 2, hasActivity: true),
    );
  });

  test('emits again when a movement is recorded', () async {
    await route('r-1');
    await load('r-1', 6);
    final emitted = <int?>[];
    final sub = sut
        .watchTruckSkeletons(DateTime(2026, 11, 25, 9))
        .listen((s) => emitted.add(s?.remaining));
    await pumpEventQueue();

    await move('m-1', visitId: 'r-1-stop', delivered: 2);
    await pumpEventQueue();
    await sub.cancel();

    expect(emitted.last, 4);
    expect(emitted.first, 6);
  });

  group('TruckSkeletons.runsShort', () {
    const truck = TruckSkeletons(loaded: 3, remaining: 2, hasActivity: true);

    test('only when the delivery leaves the truck below zero', () {
      expect(truck.runsShort(delivered: 0, returned: 0), isFalse);
      expect(truck.runsShort(delivered: 2, returned: 0), isFalse);
      expect(truck.runsShort(delivered: 3, returned: 0), isTrue);
      expect(truck.runsShort(delivered: 3, returned: 1), isFalse);
    });

    test('no delivery never runs short, even below zero', () {
      const empty = TruckSkeletons(loaded: 0, remaining: -1, hasActivity: true);
      expect(empty.runsShort(delivered: 0, returned: 0), isFalse);
      expect(empty.runsShort(delivered: 1, returned: 0), isTrue);
    });
  });
}
