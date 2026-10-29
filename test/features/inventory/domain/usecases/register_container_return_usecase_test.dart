import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/usecases/register_container_return.usecase.dart';

/// Records through Drift but fails on the [failOn]-th movement.
class _FailingInventoryRepository extends DriftInventoryRepository {
  _FailingInventoryRepository(super.db, {required this.failOn});

  final int failOn;
  int calls = 0;

  @override
  Future<void> recordContainerMovement(ContainerMovement movement) async {
    calls++;
    if (calls == failOn) throw Exception('disk full');
    await super.recordContainerMovement(movement);
  }
}

void main() {
  late AppDatabase db;
  final at = DateTime(2026, 10, 28, 9, 30);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  RegisterContainerReturnUseCase useCase(InventoryRepository repo) {
    var next = 0;
    return RegisterContainerReturnUseCase(
      inventoryRepo: repo,
      transaction: db.transaction,
      now: () => at,
      newId: () => 'mov-${next++}',
    );
  }

  test(
    'records one return movement per container type with returned > 0',
    () async {
      final result = await useCase(DriftInventoryRepository(db)).execute(
        customerId: 'cust-1',
        visitId: 'visit-1',
        routeId: 'route-1',
        returns: {'JUG': 2, 'SIPHON': 1},
      );

      expect(result, isA<Success<void>>());
      final movements = await db.select(db.containerMovementTable).get();
      expect(movements.map((m) => m.containerMovementId), ['mov-0', 'mov-1']);
      expect(movements.map((m) => m.containerType), ['JUG', 'SIPHON']);
      expect(movements.map((m) => m.returnedQuantity), [2, 1]);
      expect(movements.map((m) => m.deliveredQuantity), [0, 0]);
      expect(movements.map((m) => m.customerId).toSet(), {'cust-1'});
      expect(movements.map((m) => m.visitId).toSet(), {'visit-1'});
      expect(movements.map((m) => m.routeId).toSet(), {'route-1'});
      expect(movements.map((m) => m.createdAt).toSet(), {at});

      final custody = await db.select(db.customerContainerBalanceTable).get();
      expect(
        {for (final b in custody) b.containerType: b.quantity},
        {'JUG': -2, 'SIPHON': -1},
      );
      expect((await db.select(db.pendingChangeTable).get()).length, 2);
    },
  );

  test('skips container types returned zero times', () async {
    await useCase(
      DriftInventoryRepository(db),
    ).execute(customerId: 'cust-1', returns: {'JUG': 0, 'SIPHON': 3});

    final movement = await db.select(db.containerMovementTable).getSingle();
    expect(movement.containerType, 'SIPHON');
    expect(movement.returnedQuantity, 3);
    expect(movement.visitId, isNull);
    expect(movement.routeId, isNull);
  });

  test('records nothing when every return is zero', () async {
    final result = await useCase(
      DriftInventoryRepository(db),
    ).execute(customerId: 'cust-1', returns: {'JUG': 0, 'SIPHON': 0});

    expect(result, isA<Success<void>>());
    expect(await db.select(db.containerMovementTable).get(), isEmpty);
    expect(await db.select(db.customerContainerBalanceTable).get(), isEmpty);
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
  });

  test(
    'is atomic: a failed movement leaves no movement, custody or pending change',
    () async {
      final repo = _FailingInventoryRepository(db, failOn: 2);

      final result = await useCase(
        repo,
      ).execute(customerId: 'cust-1', returns: {'JUG': 2, 'SIPHON': 1});

      expect(result, isA<Error<void>>());
      expect(repo.calls, 2);
      expect(await db.select(db.containerMovementTable).get(), isEmpty);
      expect(await db.select(db.customerContainerBalanceTable).get(), isEmpty);
      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    },
  );
}
