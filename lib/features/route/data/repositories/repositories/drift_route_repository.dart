import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/route/data/repositories/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';

class DriftRouteRepository implements RouteRepository {
  DriftRouteRepository(this._db);

  final AppDatabase _db;

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
        _db.customerBalanceTable.customerId
            .equalsExp(_db.routeStopTable.customerId),
      ),
    ])
      ..where(_db.routeTable.route_date.equals(todayStr));

    return q.watch().asyncMap((rows) async {
      final stops = <RouteStop>[];

      for (final row in rows) {
        final stopRow = row.readTable(_db.routeStopTable);
        final custRow = row.readTable(_db.customerTable);
        final balanceRow = row.readTableOrNull(_db.customerBalanceTable);

        // Fetch primary address via secondary query.
        final addrRow = await (_db.select(_db.customerAddressTable)
              ..where((t) =>
                  t.customerId.equals(custRow.customerId) &
                  t.isPrimary.equals(true)))
            .getSingleOrNull();

        final addresses = addrRow != null
            ? [
                CustomerAddress(
                  id: addrRow.addressId,
                  street: addrRow.street,
                  isPrimary: true,
                ),
              ]
            : const <CustomerAddress>[];

        final currentBalance = balanceRow?.currentBalance ?? 0.0;
        final debtAmount = currentBalance > 0 ? currentBalance : 0.0;

        stops.add(RouteStop(
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
        ));
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
    await (_db.update(_db.routeStopTable)
          ..where((t) => t.routeStopId.equals(id)))
        .write(RouteStopTableCompanion(
      status: Value(status.name),
      visitedAt: status == StopStatus.pending
          ? const Value.absent()
          : Value(DateTime.now()),
    ));
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static StopStatus _statusFromDb(String text) =>
      StopStatus.values.firstWhere(
        (s) => s.name == text,
        orElse: () => StopStatus.pending,
      );
}
