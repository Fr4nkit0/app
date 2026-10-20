import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/services/database.helper.dart';
import 'domain/models/pending_change.dart';

typedef Json = Map<String, dynamic>;

/// Local rows that still have unsent or rejected changes; the server copy
/// must not overwrite them.
class _Unsent {
  const _Unsent({
    required this.customers,
    required this.stops,
    required this.balanceCustomers,
    required this.hasSales,
  });

  final Set<String> customers;
  final Set<String> stops;
  final Set<String> balanceCustomers;
  final bool hasSales;
}

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
      final unsent = await _loadUnsent();
      await _storeCatalogs(data);
      final productIds = await _storeProducts(data, unsent);
      final (customerIds, addressIds) = await _storeCustomers(data, productIds, unsent);
      final route = data['route'] as Json?;
      if (route != null) {
        final routeId = await _storeRoute(route);
        await _storeStops(routeId, _list(data['stops']), customerIds, addressIds, unsent);
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

  /// Downloads every page changed since the stored cursor and applies them.
  ///
  /// All pages are fetched before anything is written, then applied in one
  /// transaction together with the new cursor: a failure on any page leaves
  /// the local data and the previous cursor untouched, so the next pull
  /// repeats the same window.
  Future<void> pull() async {
    final cursor = await _storedCursor();
    final rows = <String, List<Json>>{};
    String? until;
    String? nextCursor;

    for (var page = 1; nextCursor == null; page++) {
      final response = await _dio.get(
        '/sync/pull',
        queryParameters: {
          'cursor': ?cursor,
          'until': ?until,
          'page': page,
        },
      );
      final body = Map<String, dynamic>.from(response.data as Map);
      final data = Map<String, dynamic>.from(body['data'] as Map);
      final meta = Map<String, dynamic>.from(body['meta'] as Map);
      for (final entry in data.entries) {
        rows.putIfAbsent(entry.key, () => []).addAll(_list(entry.value));
      }
      until ??= meta['until'] as String;
      if (meta['is_last_page'] == true) nextCursor = meta['cursor'] as String;
    }

    await _db.transaction(() async {
      final unsent = await _loadUnsent();
      await _storeCatalogs(rows);
      for (final p in rows['products'] ?? const <Json>[]) {
        await _upsertProduct(p);
      }
      for (final c in rows['customers'] ?? const <Json>[]) {
        await _upsertCustomer(c, c['id'] as int, unsent);
      }
      for (final a in rows['customer_addresses'] ?? const <Json>[]) {
        final customerId = await _localCustomerId(a['customer_id'] as int?);
        if (customerId == null) continue;
        await _upsertAddress(a, customerId, unsent.customers.contains(customerId));
      }
      for (final p in rows['customer_preferences'] ?? const <Json>[]) {
        final customerId = await _localCustomerId(p['customer_id'] as int?);
        if (customerId == null) continue;
        await _upsertPreference(p, customerId, unsent.customers.contains(customerId));
      }
      for (final a in rows['customer_agreements'] ?? const <Json>[]) {
        await _upsertAgreement(a);
      }
      await _replaceBalances(rows, unsent);
      for (final r in rows['routes'] ?? const <Json>[]) {
        await _storeRoute(r);
      }
      await _pullStops(rows['route_stops'] ?? const [], unsent);
      for (final i in rows['route_inventories'] ?? const <Json>[]) {
        await _upsertInventory(i, unsent);
      }
      await _saveCursor(nextCursor!);
    });
  }

  Future<String?> _storedCursor() async => (await (_db.select(_db.syncStateTable)
            ..where((t) => t.key.equals(pullCursorKey)))
          .getSingleOrNull())
      ?.value;

  Future<void> _saveCursor(String value) =>
      _db.into(_db.syncStateTable).insertOnConflictUpdate(
            SyncStateTableCompanion.insert(key: pullCursorKey, value: value),
          );

  Future<String?> _localCustomerId(int? serverId) async => serverId == null
      ? null
      : (await (_db.select(_db.customerTable)
                ..where((t) => t.serverId.equals(serverId)))
              .getSingleOrNull())
          ?.customerId;

  Future<String?> _localProductId(int? serverId) async => serverId == null
      ? null
      : (await (_db.select(_db.productTable)
                ..where((t) => t.serverId.equals(serverId)))
              .getSingleOrNull())
          ?.productId;

  Future<String?> _localAddressId(int? serverId) async => serverId == null
      ? null
      : (await (_db.select(_db.customerAddressTable)
                ..where((t) => t.serverId.equals(serverId)))
              .getSingleOrNull())
          ?.addressId;

  Future<RouteTableData?> _localRoute(int? serverId) async => serverId == null
      ? null
      : await (_db.select(_db.routeTable)
            ..where((t) => t.serverId.equals(serverId)))
          .getSingleOrNull();

  Future<String?> _localStopId(int? serverId) async => serverId == null
      ? null
      : (await (_db.select(_db.routeStopTable)
                ..where((t) => t.serverId.equals(serverId)))
              .getSingleOrNull())
          ?.routeStopId;

  /// The pull carries no price or truck stock: those keep their local values.
  Future<void> _upsertProduct(Json p) async {
    final serverId = p['id'] as int;
    final existing = await _localProductId(serverId);
    final fields = ProductTableCompanion(
      name: Value(p['name'] as String),
      description: Value(p['description'] as String?),
      enabled: _enabled(p),
      serverId: Value(serverId),
    );
    if (existing == null) {
      await _db.into(_db.productTable).insert(fields.copyWith(price: const Value(0)));
    } else {
      await (_db.update(_db.productTable)..where((t) => t.productId.equals(existing)))
          .write(fields);
    }
  }

  Future<void> _upsertAgreement(Json a) async {
    final customerId = await _localCustomerId(a['customer_id'] as int?);
    final productId = await _localProductId(a['product_id'] as int?);
    if (customerId == null || productId == null) return;
    final serverId = a['id'] as int;
    final fields = CustomerAgreementTableCompanion(
      customerId: Value(customerId),
      productId: Value(productId),
      unitPrice: Value(_toDouble(a['unit_price'])),
      validFrom: Value(_date(a['valid_from'] as String)),
      validTo: Value(a['valid_to'] == null ? null : _date(a['valid_to'] as String)),
      reason: Value(a['reason'] as String?),
      serverId: Value(serverId),
    );
    final updated = await (_db.update(_db.customerAgreementTable)
          ..where((t) => t.serverId.equals(serverId)))
        .write(fields);
    if (updated == 0) await _db.into(_db.customerAgreementTable).insert(fields);
  }

  /// Server balances replace local ones, except for customers whose unsent
  /// sales, payments or movements are still folded into the local balance.
  Future<void> _replaceBalances(Map<String, List<Json>> rows, _Unsent unsent) async {
    for (final b in rows['customer_balances'] ?? const <Json>[]) {
      final customerId = await _localCustomerId(b['customer_id'] as int?);
      if (customerId == null || unsent.balanceCustomers.contains(customerId)) continue;
      await _db.into(_db.customerBalanceTable).insertOnConflictUpdate(
            CustomerBalanceTableCompanion.insert(
              customerId: customerId,
              currentBalance: Value(_toDouble(b['current_balance'])),
              enabled: _enabled(b),
              serverId: Value(b['id'] as int),
            ),
          );
    }
    final containerCodes = {
      for (final c in await _db.select(_db.containerTypeTable).get()) c.id: c.code,
    };
    for (final b in rows['customer_container_balances'] ?? const <Json>[]) {
      final customerId = await _localCustomerId(b['customer_id'] as int?);
      final code = containerCodes[b['container_type_id'] as int];
      if (customerId == null || code == null) continue;
      if (unsent.balanceCustomers.contains(customerId)) continue;
      await _db.into(_db.customerContainerBalanceTable).insertOnConflictUpdate(
            CustomerContainerBalanceTableCompanion.insert(
              customerId: customerId,
              containerType: code,
              quantity: Value((b['balance'] as num).toInt()),
              enabled: _enabled(b),
              serverId: Value(b['id'] as int),
            ),
          );
    }
  }

  /// Stops already stored keep their sequence; new ones go to the end of
  /// their route. A stop created by the app is matched by its client uuid.
  Future<void> _pullStops(List<Json> stops, _Unsent unsent) async {
    for (final s in stops) {
      final route = await _localRoute(s['route_id'] as int?);
      final customerId = await _localCustomerId(s['customer_id'] as int?);
      if (route == null || customerId == null) continue;
      final serverId = s['id'] as int;
      final clientUuid = s['client_uuid'] as String?;
      final existing = await (_db.select(_db.routeStopTable)
            ..where((t) =>
                t.serverId.equals(serverId) |
                (clientUuid == null ? const Constant(false) : t.routeStopId.equals(clientUuid))))
          .getSingleOrNull();
      if (existing != null && unsent.stops.contains(existing.routeStopId)) continue;

      final time = s['scheduled_time'] as String?;
      final fields = RouteStopTableCompanion(
        routeId: Value(route.routeId),
        customerId: Value(customerId),
        customerAddressId: Value(await _localAddressId(s['address_id'] as int?)),
        status: Value(_stopStatus(s['status'] as String?)),
        scheduledAt: Value(_scheduledAt(route.route_date, time)),
        scheduledTime: Value(time),
        rescheduledFromStopId: Value(await _localStopId(s['is_rescheduled_from'] as int?)),
        enabled: _enabled(s),
        serverId: Value(serverId),
      );
      if (existing != null) {
        await (_db.update(_db.routeStopTable)
              ..where((t) => t.routeStopId.equals(existing.routeStopId)))
            .write(fields);
        continue;
      }
      final maxSequence = _db.routeStopTable.sequence.max();
      final last = await (_db.selectOnly(_db.routeStopTable)
            ..addColumns([maxSequence])
            ..where(_db.routeStopTable.routeId.equals(route.routeId)))
          .map((r) => r.read(maxSequence))
          .getSingle();
      await _db.into(_db.routeStopTable).insert(
            fields.copyWith(
              routeStopId: clientUuid == null ? const Value.absent() : Value(clientUuid),
              sequence: Value((last ?? 0) + 1),
            ),
          );
    }
  }

  /// Truck stock follows today's route inventory unless unsent sales already
  /// discounted it locally.
  Future<void> _upsertInventory(Json i, _Unsent unsent) async {
    final route = await _localRoute(i['route_id'] as int?);
    final productId = await _localProductId(i['product_id'] as int?);
    if (route == null || productId == null) return;
    final serverId = i['id'] as int;
    final quantity = _toDouble(i['current_quantity']).round();
    final fields = RouteInventoryLoadTableCompanion(
      routeId: Value(route.routeId),
      productId: Value(productId),
      quantity: Value(quantity),
      enabled: _enabled(i),
      serverId: Value(serverId),
    );
    final updated = await (_db.update(_db.routeInventoryLoadTable)
          ..where((t) => t.serverId.equals(serverId)))
        .write(fields);
    if (updated == 0) await _db.into(_db.routeInventoryLoadTable).insert(fields);

    if (route.route_date == _dateOnly(_today()) && !unsent.hasSales) {
      await (_db.update(_db.productTable)..where((t) => t.productId.equals(productId)))
          .write(ProductTableCompanion(stock: Value(quantity)));
    }
  }

  Future<_Unsent> _loadUnsent() async {
    final rows = await (_db.select(_db.pendingChangeTable)
          ..where((t) => t.status.isIn([
                PendingStatus.pending.wireName,
                PendingStatus.rejected.wireName,
              ])))
        .get();
    Set<String> ids(PendingEntity e) =>
        {for (final r in rows) if (r.entity == e.wireName) r.entityId};

    final visitIds = ids(PendingEntity.visit);
    final stops = ids(PendingEntity.routeStop);
    if (visitIds.isNotEmpty) {
      final visits = await (_db.select(_db.visitTable)
            ..where((t) => t.visitId.isIn(visitIds)))
          .get();
      stops.addAll(visits.map((v) => v.routeStopId));
    }

    final balanceCustomers = <String>{};
    final saleIds = ids(PendingEntity.sale);
    if (saleIds.isNotEmpty) {
      final sales = await (_db.select(_db.saleTable)
            ..where((t) => t.saleId.isIn(saleIds)))
          .get();
      balanceCustomers.addAll(sales.map((r) => r.customerId));
    }
    final paymentIds = ids(PendingEntity.payment);
    if (paymentIds.isNotEmpty) {
      final payments = await (_db.select(_db.paymentTable)
            ..where((t) => t.paymentId.isIn(paymentIds)))
          .get();
      balanceCustomers.addAll(payments.map((r) => r.customerId));
    }
    final movementIds = ids(PendingEntity.containerMovement);
    if (movementIds.isNotEmpty) {
      final movements = await (_db.select(_db.containerMovementTable)
            ..where((t) => t.containerMovementId.isIn(movementIds)))
          .get();
      balanceCustomers.addAll(movements.map((r) => r.customerId));
    }

    return _Unsent(
      customers: ids(PendingEntity.customer),
      stops: stops,
      balanceCustomers: balanceCustomers,
      hasSales: saleIds.isNotEmpty,
    );
  }

  Future<void> _storeCatalogs(Json data) async {
    for (final c in _list(data['container_types'])) {
      await _db.into(_db.containerTypeTable).insertOnConflictUpdate(
            ContainerTypeTableCompanion.insert(
              id: Value(c['id'] as int),
              code: c['code'] as String,
              description: Value(c['description'] as String?),
              enabled: _enabled(c),
            ),
          );
    }
    for (final p in _list(data['payment_methods'])) {
      await _db.into(_db.paymentMethodTable).insertOnConflictUpdate(
            PaymentMethodTableCompanion.insert(
              id: Value(p['id'] as int),
              code: p['code'] as String,
              name: p['name'] as String,
              enabled: _enabled(p),
            ),
          );
    }
    for (final o in _list(data['visit_outcomes'])) {
      await _db.into(_db.visitOutcomeTable).insertOnConflictUpdate(
            VisitOutcomeTableCompanion.insert(
              id: Value(o['id'] as int),
              name: o['name'] as String,
              triggersReschedule: Value(o['triggers_reschedule'] == true),
              enabled: _enabled(o),
            ),
          );
    }
  }

  /// Returns local product ids keyed by server id.
  Future<Map<int, String>> _storeProducts(Json data, _Unsent unsent) async {
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
            stock: unsent.hasSales ? const Value.absent() : Value(stock),
          ),
        );
        ids[serverId] = existing.productId;
      }
    }
    return ids;
  }

  /// Returns local customer and address ids, each keyed by server id.
  Future<(Map<int, String>, Map<int, String>)> _storeCustomers(
    Json data,
    Map<int, String> productIds,
    _Unsent unsent,
  ) async {
    final containerCodes = {
      for (final c in await _db.select(_db.containerTypeTable).get()) c.id: c.code,
    };
    final customerIds = <int, String>{};
    final addressIds = <int, String>{};

    for (final c in _list(data['customers'])) {
      final serverId = c['id'] as int;
      final localId = await _upsertCustomer(c, serverId, unsent);
      customerIds[serverId] = localId;
      final keepLocal = unsent.customers.contains(localId);

      for (final a in _list(c['addresses'])) {
        addressIds[a['id'] as int] = await _upsertAddress(a, localId, keepLocal);
      }

      for (final p in _list(c['preferences'])) {
        await _upsertPreference(p, localId, keepLocal);
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

      if (unsent.balanceCustomers.contains(localId)) continue;

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
    return (customerIds, addressIds);
  }

  Future<String> _upsertCustomer(Json c, int serverId, _Unsent unsent) async {
    final clientUuid = c['client_uuid'] as String?;
    final existing = await (_db.select(_db.customerTable)
          ..where((t) =>
              t.serverId.equals(serverId) |
              (clientUuid == null ? const Constant(false) : t.customerId.equals(clientUuid))))
        .getSingleOrNull();

    final fields = CustomerTableCompanion(
      name: Value(c['name'] as String),
      phone: Value(c['phone_number'] as String?),
      enabled: _enabled(c),
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
    if (!unsent.customers.contains(existing.customerId)) {
      await (_db.update(_db.customerTable)
            ..where((t) => t.customerId.equals(existing.customerId)))
          .write(fields);
    }
    return existing.customerId;
  }

  Future<String> _upsertAddress(Json a, String customerId, bool keepLocal) async {
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
      enabled: _enabled(a),
      serverId: Value(serverId),
    );
    if (existing == null) {
      return (await _db.into(_db.customerAddressTable).insertReturning(fields)).addressId;
    }
    if (!keepLocal) {
      await (_db.update(_db.customerAddressTable)
            ..where((t) => t.addressId.equals(existing.addressId)))
          .write(fields);
    }
    return existing.addressId;
  }

  Future<void> _upsertPreference(Json p, String customerId, bool keepLocal) async {
    final serverId = p['id'] as int;
    final existing = await (_db.select(_db.customerPreferenceTable)
          ..where((t) => t.serverId.equals(serverId)))
        .getSingleOrNull();
    final fields = CustomerPreferenceTableCompanion(
      customerId: Value(customerId),
      dayOfWeek: Value(p['day_of_week'] as int),
      timeWindowStart: Value((p['time_window_start'] as String?) ?? '00:00:00'),
      timeWindowEnd: Value(p['time_window_end'] as String?),
      enabled: _enabled(p),
      serverId: Value(serverId),
    );
    if (existing == null) {
      await _db.into(_db.customerPreferenceTable).insert(fields);
    } else if (!keepLocal) {
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
      enabled: _enabled(r),
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
    Map<int, String> addressIds,
    _Unsent unsent,
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
        customerAddressId: Value(addressIds[s['address_id']]),
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
        if (!unsent.stops.contains(existing.routeStopId)) {
          await (_db.update(_db.routeStopTable)
                ..where((t) => t.routeStopId.equals(existing.routeStopId)))
              .write(fields);
        }
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

  /// Server dates may arrive as full ISO timestamps; only the day matters.
  static String _date(String value) => value.substring(0, 10);

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Absent when the payload omits it, so the bootstrap keeps local flags.
  static Value<bool> _enabled(Json row) => row.containsKey('enabled')
      ? Value(row['enabled'] == true)
      : const Value.absent();

  static List<Json> _list(Object? v) =>
      (v as List<dynamic>? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  static double _toDouble(Object? v) =>
      v is num ? v.toDouble() : double.parse(v as String);

  static double? _toNullableDouble(Object? v) => v == null ? null : _toDouble(v);
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(dioProvider), ref.watch(databaseProvider));
});
