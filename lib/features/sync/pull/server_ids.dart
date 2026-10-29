import '../../../core/services/database.helper.dart';

/// Maps the server ids of a download to local ids.
///
/// The incremental pull resolves any row stored on the device. The
/// bootstrap resolves only rows of the same download, recorded as each one
/// is stored: a reference to a row the download did not carry is dropped.
class ServerIds {
  ServerIds.stored(this._db) : _downloadedOnly = false;
  ServerIds.downloaded(this._db) : _downloadedOnly = true;

  final AppDatabase _db;
  final bool _downloadedOnly;
  final _customers = <int, String>{};
  final _products = <int, String>{};
  final _addresses = <int, String>{};
  final _routes = <int, String>{};
  final _stops = <int, String>{};

  void recordCustomer(int serverId, String localId) =>
      _customers[serverId] = localId;
  void recordProduct(int serverId, String localId) =>
      _products[serverId] = localId;
  void recordAddress(int serverId, String localId) =>
      _addresses[serverId] = localId;
  void recordRoute(int serverId, String localId) => _routes[serverId] = localId;
  void recordStop(int serverId, String localId) => _stops[serverId] = localId;

  Future<String?> customer(int? serverId) => _resolve(
    serverId,
    _customers,
    (id) async => (await (_db.select(
      _db.customerTable,
    )..where((t) => t.serverId.equals(id))).getSingleOrNull())?.customerId,
  );

  Future<String?> product(int? serverId) => _resolve(
    serverId,
    _products,
    (id) async => (await (_db.select(
      _db.productTable,
    )..where((t) => t.serverId.equals(id))).getSingleOrNull())?.productId,
  );

  Future<String?> address(int? serverId) => _resolve(
    serverId,
    _addresses,
    (id) async => (await (_db.select(
      _db.customerAddressTable,
    )..where((t) => t.serverId.equals(id))).getSingleOrNull())?.addressId,
  );

  Future<String?> stop(int? serverId) => _resolve(
    serverId,
    _stops,
    (id) async => (await (_db.select(
      _db.routeStopTable,
    )..where((t) => t.serverId.equals(id))).getSingleOrNull())?.routeStopId,
  );

  Future<RouteTableData?> route(int? serverId) async {
    final routeId = await _resolve(
      serverId,
      _routes,
      (id) async => (await (_db.select(
        _db.routeTable,
      )..where((t) => t.serverId.equals(id))).getSingleOrNull())?.routeId,
    );
    if (routeId == null) return null;
    return (_db.select(
      _db.routeTable,
    )..where((t) => t.routeId.equals(routeId))).getSingleOrNull();
  }

  Future<String?> _resolve(
    int? serverId,
    Map<int, String> recorded,
    Future<String?> Function(int serverId) stored,
  ) async {
    if (serverId == null) return null;
    if (_downloadedOnly) return recorded[serverId];
    return stored(serverId);
  }
}
