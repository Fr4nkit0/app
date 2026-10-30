import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/services/database.helper.dart';
import 'pull/address_applier.dart';
import 'pull/agreement_applier.dart';
import 'pull/balance_applier.dart';
import 'pull/catalogs_applier.dart';
import 'pull/customer_applier.dart';
import 'pull/preference_applier.dart';
import 'pull/product_applier.dart';
import 'pull/pull_applier.dart';
import 'pull/route_applier.dart';
import 'pull/sale_applier.dart';
import 'pull/server_ids.dart';
import 'pull/stop_applier.dart';
import 'pull/truck_inventory_applier.dart';
import 'pull/unsent.dart';
import 'pull/visit_applier.dart';

/// Downloads the driver's full day and stores it locally.
///
/// Only orchestrates: the transaction, the cursor, the entity order and how
/// server ids are resolved. Each entity is stored by its [PullApplier], the
/// same one for the bootstrap and the incremental pull.
///
/// Never touches `pending_changes`: unsent and rejected changes survive a
/// bootstrap untouched.
class SyncService {
  SyncService(this._dio, this._db, {DateTime Function()? today})
    : _today = today ?? DateTime.now,
      _catalogs = CatalogsApplier(_db),
      _products = ProductApplier(_db),
      _customers = CustomerApplier(_db),
      _addresses = AddressApplier(_db),
      _preferences = PreferenceApplier(_db),
      _agreements = AgreementApplier(_db),
      _balances = BalanceApplier(_db),
      _routes = RouteApplier(_db),
      _stops = StopApplier(_db),
      _visits = VisitApplier(_db),
      _sales = SaleApplier(_db),
      _truckInventory = TruckInventoryApplier(
        _db,
        today: today ?? DateTime.now,
      );

  static const pullCursorKey = 'pull_cursor';

  final Dio _dio;
  final AppDatabase _db;
  final DateTime Function() _today;
  final CatalogsApplier _catalogs;
  final ProductApplier _products;
  final CustomerApplier _customers;
  final AddressApplier _addresses;
  final PreferenceApplier _preferences;
  final AgreementApplier _agreements;
  final BalanceApplier _balances;
  final RouteApplier _routes;
  final StopApplier _stops;
  final VisitApplier _visits;
  final SaleApplier _sales;
  final TruckInventoryApplier _truckInventory;

  /// Appliers of the incremental pull in dependency order: a row is applied
  /// after the rows it references.
  late final List<PullApplier> _pullOrder = [
    _catalogs,
    _products,
    _customers,
    _addresses,
    _preferences,
    _agreements,
    _balances,
    _routes,
    _stops,
    _truckInventory,
  ];

  /// True on the first run (no cursor) or when no stored route is today's.
  Future<bool> needsBootstrap() async {
    final cursor = await (_db.select(
      _db.syncStateTable,
    )..where((t) => t.key.equals(pullCursorKey))).getSingleOrNull();
    if (cursor == null) return true;

    final route =
        await (_db.select(_db.routeTable)
              ..where((t) => t.route_date.equals(dateOnly(_today())))
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
      final context = PullContext(
        unsent: await Unsent.load(_db),
        ids: ServerIds.downloaded(_db),
      );
      await _catalogs.store(data, snapshot: true);
      await _products.applySnapshot(
        jsonList(data['products']),
        jsonList(data['truck_inventory']),
        context,
      );
      for (final c in jsonList(data['customers'])) {
        final customerId = await _customers.upsert(c, context);
        await _addresses.applyForCustomer(
          customerId,
          jsonList(c['addresses']),
          context,
        );
        await _preferences.applyForCustomer(
          customerId,
          jsonList(c['preferences']),
          context,
        );
        await _agreements.replaceForCustomer(
          customerId,
          jsonList(c['agreements']),
          context,
        );
        await _balances.reconcileCustomer(customerId, c);
      }
      final route = data['route'] as Json?;
      if (route != null) {
        final routeId = await _routes.upsert(route, context);
        await _stops.replaceRoute(routeId, jsonList(data['stops']), context);
        await _truckInventory.replaceRoute(
          routeId,
          jsonList(data['truck_inventory']),
          context,
        );
      }
      // Only the bootstrap carries today's visits and sales.
      await _visits.storeToday(jsonList(data['visits']), context);
      await _sales.storeToday(jsonList(data['sales']), context);
      await _saveCursor(data['server_time'] as String);
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
        queryParameters: {'cursor': ?cursor, 'until': ?until, 'page': page},
      );
      final body = Map<String, dynamic>.from(response.data as Map);
      final data = Map<String, dynamic>.from(body['data'] as Map);
      final meta = Map<String, dynamic>.from(body['meta'] as Map);
      for (final entry in data.entries) {
        rows.putIfAbsent(entry.key, () => []).addAll(jsonList(entry.value));
      }
      until ??= meta['until'] as String;
      if (meta['is_last_page'] == true) nextCursor = meta['cursor'] as String;
    }

    await _db.transaction(() async {
      final context = PullContext(
        unsent: await Unsent.load(_db),
        ids: ServerIds.stored(_db),
      );
      for (final applier in _pullOrder) {
        await applier.applyChanges(rows, context);
      }
      await _saveCursor(nextCursor!);
    });
  }

  Future<String?> _storedCursor() async => (await (_db.select(
    _db.syncStateTable,
  )..where((t) => t.key.equals(pullCursorKey))).getSingleOrNull())?.value;

  Future<void> _saveCursor(String value) => _db
      .into(_db.syncStateTable)
      .insertOnConflictUpdate(
        SyncStateTableCompanion.insert(key: pullCursorKey, value: value),
      );
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(dioProvider), ref.watch(databaseProvider));
});
