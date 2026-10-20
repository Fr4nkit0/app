import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/route/data/repositories/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

class DriftRouteRepository implements RouteRepository {
  DriftRouteRepository(AppDatabase db)
    : _db = db,
      _queue = DriftPendingChangeRepository(db);

  final AppDatabase _db;
  final PendingChangeRepository _queue;

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
      leftOuterJoin(
        _db.customerBalanceTable,
        _db.customerBalanceTable.customerId.equalsExp(
          _db.routeStopTable.customerId,
        ),
      ),
    ])..where(
        _db.routeTable.route_date.equals(todayStr) &
            _db.routeTable.enabled.equals(true) &
            _db.routeStopTable.enabled.equals(true) &
            _db.customerTable.enabled.equals(true),
      );

    return q.watch().asyncMap((rows) async {
      final stops = <RouteStop>[];

      for (final row in rows) {
        final stopRow = row.readTable(_db.routeStopTable);
        final custRow = row.readTable(_db.customerTable);
        final balanceRow = row.readTableOrNull(_db.customerBalanceTable);

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

        final currentBalance = balanceRow?.currentBalance ?? 0.0;
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
          ),
        );
      }

      // Pending-first, then scheduledAt ascending (replicates MockRouteRepository._sortStops).
      stops.sort((a, b) {
        final aPending = a.status == StopStatus.pending;
        final bPending = b.status == StopStatus.pending;
        if (aPending != bPending) return aPending ? -1 : 1;
        return a.scheduledAt.compareTo(b.scheduledAt);
      });

      return stops;
    });
  }

  @override
  Future<void> markStop(String id, StopStatus status) async {
    final now = DateTime.now();
    await _db.transaction(() async {
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
    });
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
