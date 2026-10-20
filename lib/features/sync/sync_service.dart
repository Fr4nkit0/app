import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/services/database.helper.dart';

typedef Json = Map<String, dynamic>;

/// Downloads the driver's full day and stores it locally.
///
/// Never touches `pending_changes`: unsent and rejected changes survive a
/// bootstrap untouched.
class SyncService {
  SyncService(this._dio, this._db, {DateTime Function()? today})
    : _today = today ?? DateTime.now;

  static const pullCursorKey = 'pull_cursor';

  final Dio _dio;
  final AppDatabase _db;
  final DateTime Function() _today;

  /// True on the first run (no cursor) or when no stored route is today's.
  Future<bool> needsBootstrap() async {
    final cursor = await (_db.select(_db.syncStateTable)
          ..where((t) => t.key.equals(pullCursorKey)))
        .getSingleOrNull();
    if (cursor == null) return true;

    final route = await (_db.select(_db.routeTable)
          ..where((t) => t.route_date.equals(_dateOnly(_today())))
          ..limit(1))
        .getSingleOrNull();
    return route == null;
  }

  Future<void> bootstrapIfNeeded() async {
    if (await needsBootstrap()) await bootstrap();
  }

  Future<void> bootstrap() async {
    final response = await _dio.get('/sync/bootstrap');
    final data = Map<String, dynamic>.from(response.data['data'] as Map);

    await _db.transaction(() async {
      await _storeCatalogs(data);
      final productIds = await _storeProducts(data);
      final customerIds = await _storeCustomers(data, productIds);
      final route = data['route'] as Json?;
      if (route != null) {
        final routeId = await _storeRoute(route);
        await _storeStops(routeId, _list(data['stops']), customerIds);
        await _storeTruckInventory(routeId, _list(data['truck_inventory']), productIds);
      }
      await _db.into(_db.syncStateTable).insertOnConflictUpdate(
            SyncStateTableCompanion.insert(
              key: pullCursorKey,
              value: data['server_time'] as String,
            ),
          );
    });
  }

  Future<void> _storeCatalogs(Json data) async {
    for (final c in _list(data['container_types'])) {
      await _db.into(_db.containerTypeTable).insertOnConflictUpdate(
            ContainerTypeTableCompanion.insert(
              id: Value(c['id'] as int),
              code: c['code'] as String,
              description: Value(c['description'] as String?),
            ),
          );
    }
    for (final p in _list(data['payment_methods'])) {
      await _db.into(_db.paymentMethodTable).insertOnConflictUpdate(
            PaymentMethodTableCompanion.insert(
              id: Value(p['id'] as int),
              code: p['code'] as String,
              name: p['name'] as String,
            ),
          );
    }
    for (final o in _list(data['visit_outcomes'])) {
      await _db.into(_db.visitOutcomeTable).insertOnConflictUpdate(
            VisitOutcomeTableCompanion.insert(
              id: Value(o['id'] as int),
              name: o['name'] as String,
              triggersReschedule: Value(o['triggers_reschedule'] == true),
            ),
          );
    }
  }

  /// Returns local product ids keyed by server id.
  Future<Map<int, String>> _storeProducts(Json data) async {
    final stockByProduct = <int, int>{
      for (final i in _list(data['truck_inventory']))
        i['product_id'] as int: _toDouble(i['current_quantity']).round(),
    };
    final ids = <int, String>{};
    for (final p in _list(data['products'])) {
      final serverId = p['id'] as int;
      final stock = stockByProduct[serverId] ?? 0;
      final existing = await (_db.select(_db.productTable)
            ..where((t) => t.serverId.equals(serverId)))
          .getSingleOrNull();
      if (existing == null) {
        final row = await _db.into(_db.productTable).insertReturning(
              ProductTableCompanion.insert(
                name: p['name'] as String,
                description: Value(p['description'] as String?),
                price: p['price'] == null ? 0 : _toDouble(p['price']),
                stock: Value(stock),
                serverId: Value(serverId),
              ),
            );
        ids[serverId] = row.productId;
      } else {
        await (_db.update(_db.productTable)
              ..where((t) => t.productId.equals(existing.productId)))
            .write(
          ProductTableCompanion(
            name: Value(p['name'] as String),
            description: Value(p['description'] as String?),
            price: p['price'] == null ? const Value.absent() : Value(_toDouble(p['price'])),
            stock: Value(stock),
          ),
        );
        ids[serverId] = existing.productId;
      }
    }
    return ids;
  }

  /// Returns local customer ids keyed by server id.
  Future<Map<int, String>> _storeCustomers(
    Json data,
    Map<int, String> productIds,
  ) async {
    final containerCodes = {
      for (final c in await _db.select(_db.containerTypeTable).get()) c.id: c.code,
    };
    final customerIds = <int, String>{};

    for (final c in _list(data['customers'])) {
      final serverId = c['id'] as int;
      final localId = await _upsertCustomer(c, serverId);
      customerIds[serverId] = localId;

      final addressIds = <int, String>{};
      for (final a in _list(c['addresses'])) {
        addressIds[a['id'] as int] = await _upsertAddress(a, localId);
      }
      _addressIds.addAll(addressIds);

      for (final p in _list(c['preferences'])) {
        await _upsertPreference(p, localId);
      }

      await (_db.delete(_db.customerAgreementTable)
            ..where((t) => t.customerId.equals(localId) & t.serverId.isNotNull()))
          .go();
      for (final a in _list(c['agreements'])) {
        final productId = productIds[a['product_id'] as int];
        if (productId == null) continue;
        await _db.into(_db.customerAgreementTable).insert(
              CustomerAgreementTableCompanion.insert(
                customerId: localId,
                productId: productId,
                unitPrice: _toDouble(a['unit_price']),
                validFrom: a['valid_from'] as String,
                validTo: Value(a['valid_to'] as String?),
                reason: Value(a['reason'] as String?),
                serverId: Value(a['id'] as int),
              ),
            );
      }

      final balance = c['balance'] as Json?;
      if (balance != null) {
        await _db.into(_db.customerBalanceTable).insertOnConflictUpdate(
              CustomerBalanceTableCompanion.insert(
                customerId: localId,
                currentBalance: Value(_toDouble(balance['current_balance'])),
              ),
            );
      }

      for (final b in _list(c['container_balances'])) {
        final code = containerCodes[b['container_type_id'] as int];
        if (code == null) continue;
        await _db.into(_db.customerContainerBalanceTable).insertOnConflictUpdate(
              CustomerContainerBalanceTableCompanion.insert(
                customerId: localId,
                containerType: code,
                quantity: Value((b['balance'] as num).toInt()),
              ),
            );
      }
    }
    return customerIds;
  }

  final Map<int, String> _addressIds = {};

  Future<String> _upsertCustomer(Json c, int serverId) async {
    final clientUuid = c['client_uuid'] as String?;
    final existing = await (_db.select(_db.customerTable)
          ..where((t) =>
              t.serverId.equals(serverId) |
              (clientUuid == null ? const Constant(false) : t.customerId.equals(clientUuid))))
        .getSingleOrNull();

    final fields = CustomerTableCompanion(
      name: Value(c['name'] as String),
      phone: Value(c['phone_number'] as String?),
      serverId: Value(serverId),
    );
    if (existing == null) {
      final row = await _db.into(_db.customerTable).insertReturning(
            fields.copyWith(
              customerId: clientUuid == null ? const Value.absent() : Value(clientUuid),
            ),
          );
      return row.customerId;
    }
    await (_db.update(_db.customerTable)
          ..where((t) => t.customerId.equals(existing.customerId)))
        .write(fields);
    return existing.customerId;
  }

  Future<String> _upsertAddress(Json a, String customerId) async {
    final serverId = a['id'] as int;
    final existing = await (_db.select(_db.customerAddressTable)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
    final fields = CustomerAddressTableCompanion(
      customerId: Value(customerId),
      street: Value(a['street'] as String?),
      apartment: Value(a['apartment'] as String?),
      floor: Value(a['floor'] as String?),
      visualReference: Value(a['visual_reference'] as String?),
      isPrimary: Value(a['is_primary'] == true),
      latitude: Value(_toNullableDouble(a['latitude'])),
      longitude: Value(_toNullableDouble(a['longitude'])),
      neighborhood: Value(a['neighborhood'] as String?),
      serverId: Value(serverId),
    );
    if (existing == null) {
      return (await _db.into(_db.customerAddressTable).insertReturning(fields)).addressId;
    }
    await (_db.update(_db.customerAddressTable)
          ..where((t) => t.addressId.equals(existing.addressId)))
        .write(fields);
    return existing.addressId;
  }

  Future<void> _upsertPreference(Json p, String customerId) async {
    final serverId = p['id'] as int;
    final existing = await (_db.select(_db.customerPreferenceTable)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
    final fields = CustomerPreferenceTableCompanion(
      customerId: Value(customerId),
      dayOfWeek: Value(p['day_of_week'] as int),
      timeWindowStart: Value((p['time_window_start'] as String?) ?? '00:00:00'),
      timeWindowEnd: Value(p['time_window_end'] as String?),
      serverId: Value(serverId),
    );
    if (existing == null) {
      await _db.into(_db.customerPreferenceTable).insert(fields);
    } else {
      await (_db.update(_db.customerPreferenceTable)
            ..where((t) => t.customerPreferenceId.equals(existing.customerPreferenceId)))
          .write(fields);
    }
  }

  Future<String> _storeRoute(Json r) async {
    final serverId = r['id'] as int;
    final date = (r['date'] as String).substring(0, 10);
    final existing = await (_db.select(_db.routeTable)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
    final fields = RouteTableCompanion(
      route_date: Value(date),
      status: Value(r['status'] as String?),
      serverId: Value(serverId),
    );
    if (existing == null) {
      return (await _db.into(_db.routeTable).insertReturning(fields)).routeId;
    }
    await (_db.update(_db.routeTable)
          ..where((t) => t.routeId.equals(existing.routeId)))
        .write(fields);
    return existing.routeId;
  }

  Future<void> _storeStops(
    String routeId,
    List<Json> stops,
    Map<int, String> customerIds,
  ) async {
    final route = await (_db.select(_db.routeTable)
          ..where((t) => t.routeId.equals(routeId)))
        .getSingle();
    final stopIds = <int, String>{};

    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      final serverId = s['id'] as int;
      final customerId = customerIds[s['customer_id'] as int];
      if (customerId == null) continue;
      final time = s['scheduled_time'] as String?;
      final fields = RouteStopTableCompanion(
        routeId: Value(routeId),
        customerId: Value(customerId),
        customerAddressId: Value(_addressIds[s['address_id']]),
        sequence: Value(i + 1),
        status: Value(_stopStatus(s['status'] as String?)),
        scheduledAt: Value(_scheduledAt(route.route_date, time)),
        scheduledTime: Value(time),
        serverId: Value(serverId),
      );
      final existing = await (_db.select(_db.routeStopTable)
            ..where((t) => t.serverId.equals(serverId)))
          .getSingleOrNull();
      if (existing == null) {
        stopIds[serverId] =
            (await _db.into(_db.routeStopTable).insertReturning(fields)).routeStopId;
      } else {
        await (_db.update(_db.routeStopTable)
              ..where((t) => t.routeStopId.equals(existing.routeStopId)))
            .write(fields);
        stopIds[serverId] = existing.routeStopId;
      }
    }

    for (final s in stops) {
      final from = s['is_rescheduled_from'] as int?;
      final localId = stopIds[s['id'] as int];
      if (localId == null) continue;
      await (_db.update(_db.routeStopTable)
            ..where((t) => t.routeStopId.equals(localId)))
          .write(
        RouteStopTableCompanion(
          rescheduledFromStopId: Value(from == null ? null : stopIds[from]),
        ),
      );
    }
  }

  Future<void> _storeTruckInventory(
    String routeId,
    List<Json> items,
    Map<int, String> productIds,
  ) async {
    await (_db.delete(_db.routeInventoryLoadTable)
          ..where((t) => t.routeId.equals(routeId) & t.serverId.isNotNull()))
        .go();
    for (final i in items) {
      final productId = productIds[i['product_id'] as int];
      if (productId == null) continue;
      await _db.into(_db.routeInventoryLoadTable).insert(
            RouteInventoryLoadTableCompanion.insert(
              routeId: routeId,
              productId: productId,
              quantity: _toDouble(i['current_quantity']).round(),
              serverId: Value(i['id'] as int),
            ),
          );
    }
  }

  static String _stopStatus(String? serverStatus) => switch (serverStatus) {
    'FINISHED' => 'done',
    'CANCELLED' || 'RESCHEDULED' => 'absent',
    _ => 'pending',
  };

  static DateTime _scheduledAt(String date, String? time) {
    final day = DateTime.parse(date);
    if (time == null) return day;
    final parts = time.split(':').map(int.parse).toList();
    return DateTime(day.year, day.month, day.day, parts[0], parts[1]);
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static List<Json> _list(Object? v) =>
      (v as List<dynamic>? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  static double _toDouble(Object? v) =>
      v is num ? v.toDouble() : double.parse(v as String);

  static double? _toNullableDouble(Object? v) => v == null ? null : _toDouble(v);
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(dioProvider), ref.watch(databaseProvider));
});
