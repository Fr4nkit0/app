import '../../../../support/seed_customers.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/route/data/repositories/drift_route_repository.dart';
import 'package:app/features/route/data/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';

void main() {
  late AppDatabase db;
  late RouteRepository sut;

  final todayStr = _dateOnly(DateTime.now());
  final yesterdayStr = _dateOnly(
    DateTime.now().subtract(const Duration(days: 1)),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftRouteRepository(db);
    // A fresh database is empty; seed mock-customer-1..4 with a primary
    // address each (mock-addr-1..4) explicitly.
    await seedTestCustomers(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Future<void> insertRoute(String routeId, String dateStr) async {
    await db
        .into(db.routeTable)
        .insert(
          RouteTableCompanion.insert(
            routeId: drift.Value(routeId),
            route_date: dateStr,
          ),
        );
  }

  Future<void> insertStop({
    required String stopId,
    required String routeId,
    required String customerId,
    int sequence = 1,
    String status = 'pending',
    required DateTime scheduledAt,
  }) async {
    await db
        .into(db.routeStopTable)
        .insert(
          RouteStopTableCompanion.insert(
            routeStopId: drift.Value(stopId),
            routeId: routeId,
            customerId: customerId,
            sequence: sequence,
            status: drift.Value(status),
            scheduledAt: scheduledAt,
          ),
        );
  }

  Future<void> insertBalance(String customerId, double balance) async {
    await db
        .into(db.customerBalanceTable)
        .insertOnConflictUpdate(
          CustomerBalanceTableCompanion.insert(
            customerId: customerId,
            currentBalance: drift.Value(balance),
          ),
        );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Scenario A2 — watchDayStops returns today's stops
  // ──────────────────────────────────────────────────────────────────────────

  group('watchDayStops — today filter', () {
    test('returns 4 RouteStop objects for today route', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      for (var i = 1; i <= 4; i++) {
        await insertStop(
          stopId: 'stop-t$i',
          routeId: 'route-today',
          customerId: 'mock-customer-$i',
          sequence: i,
          scheduledAt: DateTime(now.year, now.month, now.day, 8 + i, 0),
        );
      }

      final stops = await sut.watchDayStops().first;
      expect(stops.length, 4);
    });

    test(
      'each RouteStop has a non-null customer with the correct name',
      () async {
        await insertRoute('route-today', todayStr);
        final now = DateTime.now();
        await insertStop(
          stopId: 'stop-t1',
          routeId: 'route-today',
          customerId: 'mock-customer-1',
          sequence: 1,
          scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
        );

        final stops = await sut.watchDayStops().first;
        expect(stops.first.customer, isNotNull);
        expect(stops.first.customer.name, 'José García');
      },
    );

    test('RouteStop has NO visitType field (compile-time guarantee)', () async {
      // If RouteStop had visitType this test would fail to compile.
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-t1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      final stop = stops.first;
      // RouteStop fields: id, customer, status, scheduledAt — NO visitType.
      expect(stop.id, isNotNull);
      expect(stop.customer, isNotNull);
      expect(stop.status, isNotNull);
      expect(stop.scheduledAt, isNotNull);
    });

    test(
      'debtAmount hydrated from CustomerBalanceTable (positive balance)',
      () async {
        await insertRoute('route-today', todayStr);
        await insertBalance('mock-customer-1', 1200.0);
        final now = DateTime.now();
        await insertStop(
          stopId: 'stop-t1',
          routeId: 'route-today',
          customerId: 'mock-customer-1',
          sequence: 1,
          scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
        );

        final stops = await sut.watchDayStops().first;
        expect(stops.first.customer.debtAmount, 1200.0);
      },
    );

    test('debtAmount is 0 when balance is negative (credit)', () async {
      await insertRoute('route-today', todayStr);
      await insertBalance('mock-customer-1', -500.0);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-t1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.customer.debtAmount, 0.0);
    });

    test('debtAmount is 0 when no balance row exists', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-t1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.customer.debtAmount, 0.0);
    });

    test('primary address is mapped from the seeded customer address', () async {
      // mock-customer-1 has mock-addr-1 ('Av. San Martín 1300') seeded as primary.
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-t1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.customer.addresses.length, 1);
      expect(
        stops.first.customer.addresses.first.street,
        'Av. San Martín 1300',
      );
      expect(stops.first.customer.addresses.first.isPrimary, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Scenario A3 — empty when no route for today
  // ──────────────────────────────────────────────────────────────────────────

  group('watchDayStops — date filter', () {
    test('returns empty list when route_date is yesterday', () async {
      await insertRoute('route-yesterday', yesterdayStr);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await insertStop(
        stopId: 'stop-y1',
        routeId: 'route-yesterday',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: yesterday,
      );

      final stops = await sut.watchDayStops().first;
      expect(stops, isEmpty);
    });

    test('returns empty list when no routes exist at all', () async {
      final stops = await sut.watchDayStops().first;
      expect(stops, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Ordering: pending-first, then scheduledAt asc
  // ──────────────────────────────────────────────────────────────────────────

  group('watchDayStops — ordering', () {
    test('pending stops appear before done stops', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      // done stop has earlier scheduledAt; pending has later — pending must still come first.
      await insertStop(
        stopId: 'stop-done',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        status: 'done',
        scheduledAt: DateTime(now.year, now.month, now.day, 8, 0),
      );
      await insertStop(
        stopId: 'stop-pending',
        routeId: 'route-today',
        customerId: 'mock-customer-2',
        sequence: 2,
        status: 'pending',
        scheduledAt: DateTime(now.year, now.month, now.day, 10, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.id, 'stop-pending');
      expect(stops.last.id, 'stop-done');
    });

    test('among pending stops, earlier scheduledAt comes first', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-late',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 11, 0),
      );
      await insertStop(
        stopId: 'stop-early',
        routeId: 'route-today',
        customerId: 'mock-customer-2',
        sequence: 2,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.id, 'stop-early');
      expect(stops.last.id, 'stop-late');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Scenario A4 — markStop
  // ──────────────────────────────────────────────────────────────────────────

  group('markStop', () {
    test('sets status to done and non-null visitedAt', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      await sut.markStop('stop-1', StopStatus.done);

      final row = await (db.select(
        db.routeStopTable,
      )..where((t) => t.routeStopId.equals('stop-1'))).getSingle();
      expect(row.status, 'done');
      expect(row.visitedAt, isNotNull);
    });

    test('does not modify VisitTable', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      await sut.markStop('stop-1', StopStatus.done);

      final visits = await db.select(db.visitTable).get();
      expect(visits, isEmpty);
    });

    test('sets absent status correctly', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      await sut.markStop('stop-1', StopStatus.absent);

      final row = await (db.select(
        db.routeStopTable,
      )..where((t) => t.routeStopId.equals('stop-1'))).getSingle();
      expect(row.status, 'absent');
      expect(row.visitedAt, isNotNull);
    });

    test('stream re-emits after markStop with updated status', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final emissions = <List<RouteStop>>[];
      final sub = sut.watchDayStops().listen(emissions.add);
      addTearDown(sub.cancel);

      await Future.delayed(const Duration(milliseconds: 30));
      expect(emissions.last.first.status, StopStatus.pending);

      await sut.markStop('stop-1', StopStatus.done);
      await Future.delayed(const Duration(milliseconds: 30));

      expect(emissions.last.first.status, StopStatus.done);
    });
  });

  group('rescheduleStop', () {
    test(
      'adds a stop of the same customer to today\'s route at the chosen time, linked to the original, which shows as rescheduled',
      () async {
        await insertRoute('route-today', todayStr);
        final now = DateTime.now();
        final original = DateTime(now.year, now.month, now.day, 9, 0);
        await insertStop(
          stopId: 'stop-1',
          routeId: 'route-today',
          customerId: 'mock-customer-1',
          sequence: 1,
          scheduledAt: original,
        );
        final at = DateTime(now.year, now.month, now.day, 16, 30);

        final newId = await sut.rescheduleStop('stop-1', at);

        final stops = await sut.watchDayStops().first;
        final created = stops.singleWhere((s) => s.id == newId);
        final old = stops.singleWhere((s) => s.id == 'stop-1');
        expect(created.status, StopStatus.pending);
        expect(created.customer.id, 'mock-customer-1');
        expect(created.scheduledAt, at);
        expect(created.hasScheduledTime, isTrue);
        expect(created.rescheduledFromStopId, 'stop-1');
        expect(created.rescheduledFromAt, original);
        expect(old.status, StopStatus.rescheduled);
        final row = await (db.select(
          db.routeStopTable,
        )..where((t) => t.routeStopId.equals(newId))).getSingle();
        expect(row.routeId, 'route-today');
        expect(row.scheduledTime, '16:30:00');
      },
    );

    test('the original stop carries the time it was rescheduled to', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );
      final at = DateTime(now.year, now.month, now.day, 16, 30);

      await sut.rescheduleStop('stop-1', at);

      final stops = await sut.watchDayStops().first;
      expect(stops.singleWhere((s) => s.id == 'stop-1').rescheduledToAt, at);
      expect(
        stops.singleWhere((s) => s.id != 'stop-1').rescheduledToAt,
        isNull,
      );
    });

    test('a stop that was not rescheduled carries no link', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stop = (await sut.watchDayStops().first).single;

      expect(stop.rescheduledFromStopId, isNull);
      expect(stop.rescheduledFromAt, isNull);
    });
  });

  group('watchDayStops — requested visit', () {
    Future<void> markRequested(
      String stopId, {
      String? note,
      bool enabled = true,
    }) => (db.update(
      db.routeStopTable,
    )..where((t) => t.routeStopId.equals(stopId))).write(
      RouteStopTableCompanion(
        isRequested: const drift.Value(true),
        note: drift.Value(note),
        enabled: drift.Value(enabled),
      ),
    );

    Future<void> seedTodayStop(String stopId, {int hour = 9}) async {
      final now = DateTime.now();
      await insertStop(
        stopId: stopId,
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        scheduledAt: DateTime(now.year, now.month, now.day, hour),
      );
    }

    setUp(() => insertRoute('route-today', todayStr));

    test('exposes the mark and the note of a requested stop', () async {
      await seedTodayStop('stop-1');
      await seedTodayStop('stop-2', hour: 10);
      await markRequested('stop-1', note: 'Llamar antes');

      final stops = await sut.watchDayStops().first;

      final requested = stops.singleWhere((s) => s.id == 'stop-1');
      expect(requested.isRequested, isTrue);
      expect(requested.note, 'Llamar antes');
      final normal = stops.singleWhere((s) => s.id == 'stop-2');
      expect(normal.isRequested, isFalse);
      expect(normal.note, isNull);
    });

    test('hides a disabled requested stop', () async {
      await seedTodayStop('stop-1');
      await markRequested('stop-1', note: 'Llamar antes', enabled: false);

      expect(await sut.watchDayStops().first, isEmpty);
    });

    test(
      'a stop rescheduled from a requested stop shows the same mark',
      () async {
        await seedTodayStop('stop-1');
        await markRequested('stop-1', note: 'Llamar antes');
        final now = DateTime.now();

        final newId = await sut.rescheduleStop(
          'stop-1',
          DateTime(now.year, now.month, now.day, 16, 30),
        );

        final created = (await sut.watchDayStops().first).singleWhere(
          (s) => s.id == newId,
        );
        expect(created.isRequested, isTrue);
        expect(created.note, 'Llamar antes');
        // The mark is read from the original, not copied onto the new row.
        final row = await (db.select(
          db.routeStopTable,
        )..where((t) => t.routeStopId.equals(newId))).getSingle();
        expect(row.isRequested, isFalse);
        expect(row.note, isNull);

        // Rescheduling again still reaches the requested original.
        final againId = await sut.rescheduleStop(
          newId,
          DateTime(now.year, now.month, now.day, 18),
        );
        final again = (await sut.watchDayStops().first).singleWhere(
          (s) => s.id == againId,
        );
        expect(again.isRequested, isTrue);
        expect(again.note, 'Llamar antes');
      },
    );

    test('a stop rescheduled from a normal stop is not requested', () async {
      await seedTodayStop('stop-1');
      final now = DateTime.now();

      final newId = await sut.rescheduleStop(
        'stop-1',
        DateTime(now.year, now.month, now.day, 16, 30),
      );

      final created = (await sut.watchDayStops().first).singleWhere(
        (s) => s.id == newId,
      );
      expect(created.isRequested, isFalse);
      expect(created.note, isNull);
    });
  });

  group('watchDayStops — visit summary', () {
    Future<void> closedStop(String stopId, {int? outcomeId}) async {
      final now = DateTime.now();
      await insertStop(
        stopId: stopId,
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        status: 'done',
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );
      await db
          .into(db.visitTable)
          .insert(
            VisitTableCompanion.insert(
              routeStopId: stopId,
              customerId: 'mock-customer-1',
              visitType: outcomeId == null ? 'sale' : 'visit',
              outcomeId: drift.Value(outcomeId),
              arrived_at: now,
            ),
          );
    }

    Future<void> sale(String id, String stopId, double total, String method) =>
        db
            .into(db.saleTable)
            .insert(
              SaleTableCompanion.insert(
                saleId: drift.Value(id),
                customerId: 'mock-customer-1',
                totalAmount: total,
                paymentMethod: method,
                quantity: 0,
                shipping_amount: 0,
                visitId: drift.Value(stopId),
              ),
            );

    Future<void> payment(String stopId, double amount, {String? saleId}) => db
        .into(db.paymentTable)
        .insert(
          PaymentTableCompanion.insert(
            customerId: 'mock-customer-1',
            amount: amount,
            paymentMethod: 'EFECTIVO',
            visitId: drift.Value(stopId),
            saleId: drift.Value(saleId),
          ),
        );

    Future<void> containerReturn(String stopId, String type, int qty) => db
        .into(db.containerMovementTable)
        .insert(
          ContainerMovementTableCompanion.insert(
            customerId: 'mock-customer-1',
            containerType: type,
            deliveredQuantity: 1,
            returnedQuantity: qty,
            visitId: drift.Value(stopId),
          ),
        );

    setUp(() async {
      await insertRoute('route-today', todayStr);
      await db
          .into(db.visitOutcomeTable)
          .insert(
            VisitOutcomeTableCompanion.insert(
              id: drift.Value(2),
              code: const drift.Value('refused'),
              name: 'No quiso',
            ),
          );
    });

    test('a sale visit sums its sales and their methods, without the '
        'payments that settle them', () async {
      await closedStop('stop-1');
      await sale('sale-1', 'stop-1', 5000, 'cash');
      await sale('sale-2', 'stop-1', 700, 'cash');
      await payment('stop-1', 5000, saleId: 'sale-1');

      final visit = (await sut.watchDayStops().first).single.visit!;

      expect(visit.outcome, isNull);
      expect(visit.salesTotal, 5700);
      expect(visit.saleMethods, [PaymentMethod.cash]);
      expect(visit.collected, 0);
      expect(visit.returned, 0);
    });

    test('a visit without sale carries its outcome, the payments and the '
        'containers returned', () async {
      await closedStop('stop-1', outcomeId: 2);
      await payment('stop-1', 2000);
      await containerReturn('stop-1', 'BIDON_20L', 2);
      await containerReturn('stop-1', 'SIFON_2L', 1);

      final visit = (await sut.watchDayStops().first).single.visit!;

      expect(visit.outcome?.name, 'No quiso');
      expect(visit.outcome?.code, 'refused');
      expect(visit.visitId, isNotNull);
      expect(visit.arrivedAt, isNotNull);
      expect(visit.hasSales, isFalse);
      expect(visit.collected, 2000);
      expect(visit.returned, 3);
    });

    test('cancelled sales and payments no longer count in the '
        'summary', () async {
      await closedStop('stop-1');
      await sale('sale-1', 'stop-1', 5000, 'cash');
      await sale('sale-2', 'stop-1', 700, 'credit');
      await payment('stop-1', 300);
      await payment('stop-1', 200);
      await db.customStatement(
        "UPDATE sales SET status = 'CANCELLED' WHERE sale_id = 'sale-2'",
      );
      await db.customStatement(
        "UPDATE payments SET status = 'CANCELLED' WHERE amount = 200",
      );

      final visit = (await sut.watchDayStops().first).single.visit!;

      expect(visit.salesTotal, 5000);
      expect(visit.saleMethods, [PaymentMethod.cash]);
      expect(visit.collected, 300);
    });

    test('a stop without a visit has no summary', () async {
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      expect((await sut.watchDayStops().first).single.visit, isNull);
    });

    test('re-emits when a record of the visit is written', () async {
      await closedStop('stop-1', outcomeId: 2);
      final emissions = <List<RouteStop>>[];
      final sub = sut.watchDayStops().listen(emissions.add);
      addTearDown(sub.cancel);
      await Future.delayed(const Duration(milliseconds: 30));

      await payment('stop-1', 2000);
      await Future.delayed(const Duration(milliseconds: 30));

      expect(emissions.last.single.visit?.collected, 2000);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // A disabled customer keeps its closed stops of the day
  // ──────────────────────────────────────────────────────────────────────────

  group('watchDayStops — disabled customer', () {
    final now = DateTime.now();
    DateTime at(int hour) => DateTime(now.year, now.month, now.day, hour);

    Future<void> disableCustomer(String customerId) => (db.update(
      db.customerTable,
    )..where((t) => t.customerId.equals(customerId))).write(
      const CustomerTableCompanion(enabled: drift.Value(false)),
    );

    Future<void> visit(String stopId, String customerId) => db
        .into(db.visitTable)
        .insert(
          VisitTableCompanion.insert(
            routeStopId: stopId,
            customerId: customerId,
            visitType: 'sale',
            arrived_at: now,
          ),
        );

    setUp(() async {
      await insertRoute('route-today', todayStr);
      // mock-customer-1: a stop closed with a cash sale; a pending one later.
      await insertStop(
        stopId: 'stop-closed',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        status: 'done',
        scheduledAt: at(9),
      );
      await visit('stop-closed', 'mock-customer-1');
      await db
          .into(db.saleTable)
          .insert(
            SaleTableCompanion.insert(
              saleId: const drift.Value('sale-1'),
              customerId: 'mock-customer-1',
              totalAmount: 5700,
              paymentMethod: 'cash',
              quantity: 0,
              shipping_amount: 0,
              visitId: const drift.Value('stop-closed'),
            ),
          );
      await insertStop(
        stopId: 'stop-pending',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 2,
        scheduledAt: at(15),
      );
      // mock-customer-2 stays enabled with one pending stop.
      await insertStop(
        stopId: 'stop-other',
        routeId: 'route-today',
        customerId: 'mock-customer-2',
        sequence: 3,
        scheduledAt: at(11),
      );
    });

    test('its closed stop stays with its visit summary', () async {
      await disableCustomer('mock-customer-1');

      final stops = await sut.watchDayStops().first;
      final closed = stops.where((s) => s.id == 'stop-closed').single;

      expect(closed.status, StopStatus.done);
      expect(closed.customer.name, 'José García');
      expect(closed.visit?.salesTotal, 5700);
      expect(closed.visit?.saleMethods, [PaymentMethod.cash]);
    });

    test('its absent and rescheduled stops stay too', () async {
      await insertStop(
        stopId: 'stop-absent',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 4,
        status: 'absent',
        scheduledAt: at(10),
      );
      await insertStop(
        stopId: 'stop-rescheduled',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 5,
        status: 'rescheduled',
        scheduledAt: at(12),
      );
      await disableCustomer('mock-customer-1');

      final ids = (await sut.watchDayStops().first).map((s) => s.id);

      expect(ids, containsAll(['stop-absent', 'stop-rescheduled']));
    });

    test('a pending stop with a recorded visit stays', () async {
      await visit('stop-pending', 'mock-customer-1');
      await disableCustomer('mock-customer-1');

      final ids = (await sut.watchDayStops().first).map((s) => s.id);

      expect(ids, contains('stop-pending'));
    });

    test('its pending stop without a visit is hidden', () async {
      await disableCustomer('mock-customer-1');

      final ids = (await sut.watchDayStops().first).map((s) => s.id);

      expect(ids, isNot(contains('stop-pending')));
      expect(ids, containsAll(['stop-closed', 'stop-other']));
    });

    test('the day counters count the closed stop and not the pending '
        'one', () async {
      await disableCustomer('mock-customer-1');

      final stops = await sut.watchDayStops().first;
      final pending = stops.where((s) => s.status == StopStatus.pending);

      expect(stops.length, 2);
      expect(stops.length - pending.length, 1);
      expect(pending.map((s) => s.id), ['stop-other']);
    });

    test('disabling the customer while watching drops only the pending '
        'stop', () async {
      final emissions = <List<RouteStop>>[];
      final sub = sut.watchDayStops().listen(emissions.add);
      addTearDown(sub.cancel);
      await Future.delayed(const Duration(milliseconds: 30));
      expect(emissions.last.length, 3);

      await disableCustomer('mock-customer-1');
      await Future.delayed(const Duration(milliseconds: 30));

      expect(emissions.last.map((s) => s.id), [
        'stop-other',
        'stop-closed',
      ]);
    });
  });
}

// ──────────────────────────────────────────────────────────────────────────
// Utility
// ──────────────────────────────────────────────────────────────────────────

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
