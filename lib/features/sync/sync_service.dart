import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/database.helper.dart';

class SyncService {
  final Dio _dio;
  final AppDatabase _db;

  SyncService(this._dio, this._db);

  Future<void> bootstrap() async {
    try {
      final response = await _dio.get('/sync/bootstrap');
      final data = response.data['data'];

      await _db.transaction(() async {
        // Hydrate Customers
        final customers = data['customers'] as List<dynamic>? ?? [];
        for (final c in customers) {
          final serverId = c['id'] as int;
          var existing = await (_db.select(_db.customerTable)..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
          
          if (existing == null) {
            await _db.into(_db.customerTable).insert(
              CustomerTableCompanion.insert(
                name: c['name'],
                phone: Value(c['phone_number']),
                serverId: Value(serverId),
              ),
            );
          } else {
            await (_db.update(_db.customerTable)..where((t) => t.serverId.equals(serverId))).write(
              CustomerTableCompanion(
                name: Value(c['name']),
                phone: Value(c['phone_number']),
              ),
            );
          }
        }

        // Hydrate Products
        final products = data['products'] as List<dynamic>? ?? [];
        for (final p in products) {
          final serverId = p['id'] as int;
          var existing = await (_db.select(_db.productTable)..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
          if (existing == null) {
            await _db.into(_db.productTable).insert(
              ProductTableCompanion.insert(
                name: p['name'],
                price: p['price'] is int ? (p['price'] as int).toDouble() : (p['price'] as double? ?? 0.0),
                serverId: Value(serverId),
              ),
            );
          }
        }
        
        // Similar hydration for route, stops, container_types, etc...
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncOfflineRecords() async {
    try {
      // 1. Sync offline Customers
      final offlineCustomers = await (_db.select(_db.customerTable)
        ..where((t) => t.serverId.isNull())).get();
      
      if (offlineCustomers.isNotEmpty) {
        final payload = {
          'customers': offlineCustomers.map((c) => {
            'uuid': c.customerId,
            'name': c.name,
            'phone_number': c.phone,
            'address': {
              'street': 'Offline Street', // Placeholder, would fetch real address
              'latitude': null,
              'longitude': null,
            },
          }).toList(),
        };

        final response = await _dio.post('/sync/customers', data: payload);
        final createdCustomers = response.data['data']['created_customers'] as List<dynamic>;

        // Update local records with server_id
        for (final cc in createdCustomers) {
          final uuid = cc['uuid'] as String;
          final serverId = cc['server_id'] as int;
          await (_db.update(_db.customerTable)..where((t) => t.customerId.equals(uuid))).write(
            CustomerTableCompanion(serverId: Value(serverId)),
          );
        }
      }

            // 2. Sync offline Visits & Operations
      final offlineVisits = await (_db.select(_db.visitTable)..where((t) => t.serverId.isNull())).get();
      final offlineSales = await (_db.select(_db.saleTable)..where((t) => t.serverId.isNull())).get();
      final offlinePayments = await (_db.select(_db.paymentTable)..where((t) => t.serverId.isNull())).get();
      final offlineMovements = await (_db.select(_db.containerMovementTable)..where((t) => t.serverId.isNull())).get();

      final visitsPayload = [];
      
      // Process standard visits
      for (final v in offlineVisits) {
        final customer = await (_db.select(_db.customerTable)..where((t) => t.customerId.equals(v.customerId))).getSingle();
        final vSales = offlineSales.where((s) => s.visitId == v.visitId).toList();
        final vPayments = offlinePayments.where((p) => p.visitId == v.visitId).toList();
        final vMovements = offlineMovements.where((m) => m.visitId == v.visitId).toList();
        
        visitsPayload.add({
          'uuid': v.visitId,
          'customer_id': customer.serverId,
          'route_stop_id': null,
          'outcome_id': null,
          'status': v.outcome,
          'notes': v.observations,
          'sales': vSales.map((s) => {
            'uuid': s.saleId,
            'total': s.totalAmount,
            'details': [{'product_id': 1, 'quantity': s.quantity, 'unit_price': s.totalAmount / (s.quantity > 0 ? s.quantity : 1)}],
          }).toList(),
          'payments': vPayments.map((p) => {
            'uuid': p.paymentId,
            'amount': p.amount,
            'payment_method_id': 1,
          }).toList(),
          'container_movements': vMovements.map((m) => {
            'uuid': m.containerMovementId,
            'container_type_id': 1,
            'quantity': m.deliveredQuantity,
            'movement_type': 'DELIVERED',
          }).toList(),
        });
      }

      // Process orphaned operations (lacking visit_id) by generating ad-hoc visits per customer
      final orphanSales = offlineSales.where((s) => s.visitId == null).toList();
      final orphanPayments = offlinePayments.where((p) => p.visitId == null).toList();
      final orphanMovements = offlineMovements.where((m) => m.visitId == null).toList();
      
      final orphanCustomerIds = <String>{
        ...orphanSales.map((s) => s.customerId),
        ...orphanPayments.map((p) => p.customerId),
        ...orphanMovements.map((m) => m.customerId),
      };
      
      for (final cid in orphanCustomerIds) {
        final customer = await (_db.select(_db.customerTable)..where((t) => t.customerId.equals(cid))).getSingle();
        final cSales = orphanSales.where((s) => s.customerId == cid).toList();
        final cPayments = orphanPayments.where((p) => p.customerId == cid).toList();
        final cMovements = orphanMovements.where((m) => m.customerId == cid).toList();
        
        visitsPayload.add({
          'uuid': const Uuid().v4(), // Ad-hoc visit UUID
          'customer_id': customer.serverId,
          'route_stop_id': null,
          'outcome_id': null,
          'status': 'FINISHED',
          'notes': 'Ad-hoc visit for standalone operations',
          'sales': cSales.map((s) => {
            'uuid': s.saleId,
            'total': s.totalAmount,
            'details': [{'product_id': 1, 'quantity': s.quantity, 'unit_price': s.totalAmount / (s.quantity > 0 ? s.quantity : 1)}],
          }).toList(),
          'payments': cPayments.map((p) => {
            'uuid': p.paymentId,
            'amount': p.amount,
            'payment_method_id': 1,
          }).toList(),
          'container_movements': cMovements.map((m) => {
            'uuid': m.containerMovementId,
            'container_type_id': 1,
            'quantity': m.deliveredQuantity,
            'movement_type': 'DELIVERED',
          }).toList(),
        });
      }

      if (visitsPayload.isNotEmpty) {
        final payload = {'visits': visitsPayload};
        await _dio.post('/sync/route-visits', data: payload);
      }

    } catch (e) {
      rethrow;
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(dioProvider),
    ref.watch(databaseProvider),
  );
});
