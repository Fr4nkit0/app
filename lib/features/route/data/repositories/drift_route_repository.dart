import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/payments/data/repositories/customer_account.dart';
import 'package:app/features/route/data/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/domain/models/visit_summary.dart';

class DriftRouteRepository implements RouteRepository {
  DriftRouteRepository(AppDatabase db)
    : _db = db,
      _queue = DriftPendingChangeRepository(db),
      _account = CustomerAccount(db);

  final AppDatabase _db;
  final PendingChangeRepository _queue;
  final CustomerAccount _account;

  @override
  Stream<List<RouteStop>> watchDayStops() {
    final todayStr = _dateOnly(DateTime.now());

    final q = _db.select(_db.routeStopTable).join([
      innerJoin(
        _db.routeTable,
        _db.routeTable.routeId.equalsExp(_db.routeStopTable.routeId),
      ),
      innerJoin(
        _db.customerTable,
        _db.customerTable.customerId.equalsExp(_db.routeStopTable.customerId),
      ),
      _account.balanceJoin(_db.routeStopTable.customerId),
    ])..where(
        _db.routeTable.route_date.equals(todayStr) &
            _db.routeTable.enabled.equals(true) &
            _db.routeStopTable.enabled.equals(true) &
            _db.customerTable.enabled.equals(true),
      );

    // The joined query alone would not re-emit when a visit or one of its
    // records changes, so any of these tables triggers a fresh read.
    final changes = _db
        .customSelect(
          'SELECT 1',
          readsFrom: {
            _db.routeStopTable,
            _db.routeTable,
            _db.customerTable,
            _account.watchedTable,
            _db.visitTable,
            _db.visitOutcomeTable,
            _db.saleTable,
            _db.paymentTable,
            _db.containerMovementTable,
          },
        )
        .watch();

    return changes.asyncMap((_) async {
      final rows = await q.get();
      final stops = <RouteStop>[];
      final stopRows = [
        for (final row in rows) row.readTable(_db.routeStopTable),
      ];
      final scheduledAtById = {
        for (final stop in stopRows) stop.routeStopId: stop.scheduledAt,
      };
      final rescheduledToById = {
        for (final stop in stopRows)
          if (stop.rescheduledFromStopId != null)
            stop.rescheduledFromStopId!: stop.scheduledAt,
      };
      final visits = await _visitSummaries([
        for (final stop in stopRows) stop.routeStopId,
      ]);

      for (final row in rows) {
        final stopRow = row.readTable(_db.routeStopTable);
        final custRow = row.readTable(_db.customerTable);

        // Fetch primary address via secondary query.
        final addrRow =
            await (_db.select(_db.customerAddressTable)..where(
                  (t) =>
                      t.customerId.equals(custRow.customerId) &
                      t.isPrimary.equals(true) &
                      t.enabled.equals(true),
                ))
                .getSingleOrNull();

        final addresses = addrRow != null
            ? [
                CustomerAddress(
                  id: addrRow.addressId,
                  street: addrRow.street,
                  apartment: addrRow.apartment,
                  floor: addrRow.floor,
                  visualReference: addrRow.visualReference,
                  isPrimary: true,
                  latitude: addrRow.latitude,
                  longitude: addrRow.longitude,
                ),
              ]
            : const <CustomerAddress>[];

        final currentBalance = _account.balanceIn(row);
        final debtAmount = currentBalance > 0 ? currentBalance : 0.0;

        stops.add(
          RouteStop(
            id: stopRow.routeStopId,
            customer: Customer(
              id: custRow.customerId,
              name: custRow.name,
              phone: custRow.phone,
              addresses: addresses,
              preferences: const [],
              debtAmount: debtAmount,
              productLabels: const [],
            ),
            status: _statusFromDb(stopRow.status),
            scheduledAt: stopRow.scheduledAt,
            hasScheduledTime: stopRow.scheduledTime != null,
            rescheduledFromStopId: stopRow.rescheduledFromStopId,
            rescheduledFromAt: scheduledAtById[stopRow.rescheduledFromStopId],
            rescheduledToAt: rescheduledToById[stopRow.routeStopId],
            visit: visits[stopRow.routeStopId],
          ),
        );
      }

      // Pending-first, then scheduledAt ascending.
      stops.sort((a, b) {
        final aPending = a.status == StopStatus.pending;
        final bPending = b.status == StopStatus.pending;
        if (aPending != bPending) return aPending ? -1 : 1;
        return a.scheduledAt.compareTo(b.scheduledAt);
      });

      return stops;
    });
  }

  /// The summary of each stop in [stopIds] with a recorded visit. Sales,
  /// payments and container movements of a visit carry its stop's id.
  Future<Map<String, VisitSummary>> _visitSummaries(
    List<String> stopIds,
  ) async {
    if (stopIds.isEmpty) return const {};

    final visitRows =
        await (_db.select(_db.visitTable).join([
                leftOuterJoin(
                  _db.visitOutcomeTable,
                  _db.visitOutcomeTable.id.equalsExp(_db.visitTable.outcomeId),
                ),
              ])
              ..where(_db.visitTable.routeStopId.isIn(stopIds))
              ..orderBy([OrderingTerm.asc(_db.visitTable.arrived_at)]))
            .get();
    // The latest visit of a stop decides its outcome.
    final outcomes = <String, VisitOutcome?>{};
    for (final row in visitRows) {
      final outcome = row.readTableOrNull(_db.visitOutcomeTable);
      outcomes[row.readTable(_db.visitTable).routeStopId] = outcome == null
          ? null
          : VisitOutcome(
              id: outcome.id,
              code: outcome.code,
              name: outcome.name,
              triggersReschedule: outcome.triggersReschedule,
            );
    }
    if (outcomes.isEmpty) return const {};
    final visited = outcomes.keys.toList();

    final sales =
        await (_db.select(_db.saleTable)
              ..where((t) => t.visitId.isIn(visited))
              ..orderBy([(t) => OrderingTerm.asc(t.saleDate)]))
            .get();
    final payments = await (_db.select(
      _db.paymentTable,
    )..where((t) => t.visitId.isIn(visited) & t.saleId.isNull())).get();
    final movements = await (_db.select(
      _db.containerMovementTable,
    )..where((t) => t.visitId.isIn(visited))).get();

    return {
      for (final stopId in visited)
        stopId: VisitSummary(
          outcome: outcomes[stopId],
          salesTotal: sales
              .where((s) => s.visitId == stopId)
              .fold(0.0, (sum, s) => sum + s.totalAmount),
          saleMethods: {
            for (final s in sales)
              if (s.visitId == stopId)
                PaymentMethod.values.firstWhere(
                  (m) => m.name == s.paymentMethod,
                  orElse: () => PaymentMethod.cash,
                ),
          }.toList(),
          collected: payments
              .where((p) => p.visitId == stopId)
              .fold(0.0, (sum, p) => sum + p.amount),
          returned: movements
              .where((m) => m.visitId == stopId)
              .fold(0, (sum, m) => sum + m.returnedQuantity),
        ),
    };
  }

  @override
  Future<void> markStop(String id, StopStatus status) async {
    final now = DateTime.now();
    final updated =
        await (_db.update(
          _db.routeStopTable,
        )..where((t) => t.routeStopId.equals(id))).write(
          RouteStopTableCompanion(
            status: Value(status.name),
            visitedAt: status == StopStatus.pending
                ? const Value.absent()
                : Value(now),
            lastModifiedDate: Value(now),
          ),
        );
    if (updated == 0) return;

    await _queue.enqueue(
      entity: PendingEntity.routeStop,
      entityId: id,
      action: PendingAction.update,
      payload: {
        'routeStopId': id,
        'status': status.name,
        'visitedAt': status == StopStatus.pending
            ? null
            : now.toIso8601String(),
      },
    );
  }

  @override
  Future<String> rescheduleStop(String stopId, DateTime at) async {
    final original = await (_db.select(
      _db.routeStopTable,
    )..where((t) => t.routeStopId.equals(stopId))).getSingle();
    await markStop(stopId, StopStatus.rescheduled);

    final maxSequence = _db.routeStopTable.sequence.max();
    final last =
        await (_db.selectOnly(_db.routeStopTable)
              ..addColumns([maxSequence])
              ..where(_db.routeStopTable.routeId.equals(original.routeId)))
            .map((r) => r.read(maxSequence))
            .getSingle();
    final time =
        '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}:00';
    final created = await _db
        .into(_db.routeStopTable)
        .insertReturning(
          RouteStopTableCompanion.insert(
            routeId: original.routeId,
            customerId: original.customerId,
            customerAddressId: Value(original.customerAddressId),
            sequence: (last ?? 0) + 1,
            scheduledAt: at,
            scheduledTime: Value(time),
            rescheduledFromStopId: Value(stopId),
          ),
        );

    await _queue.enqueue(
      entity: PendingEntity.routeStop,
      entityId: created.routeStopId,
      action: PendingAction.insert,
      payload: {
        'routeStopId': created.routeStopId,
        'rescheduledFromStopId': stopId,
        'scheduledTime': time,
      },
    );
    return created.routeStopId;
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static StopStatus _statusFromDb(String text) => StopStatus.values.firstWhere(
    (s) => s.name == text,
    orElse: () => StopStatus.pending,
  );
}
