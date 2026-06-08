import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriftCustomerRepository implements CustomerRepository {
  final AppDatabase db;

  DriftCustomerRepository(this.db);

  @override
  Future<Resource<void>> saveCustomer(Customer customer) async {
    try {
      return await db.transaction(() async {
        await db
            .into(db.customerTable)
            .insertOnConflictUpdate(
              CustomerTableCompanion.insert(
                customerId: Value(customer.id),
                name: customer.name,
                phone: Value(customer.phone),
              ),
            );
        for (final address in customer.addresses) {
          await db
              .into(db.customerAddressTable)
              .insertOnConflictUpdate(
                CustomerAddressTableCompanion.insert(
                  addressId: Value(address.id),
                  customerId: Value(customer.id),
                  street: Value(address.street),
                  apartment: Value(address.apartment),
                  floor: Value(address.floor),
                  visualReference: Value(address.visualReference),
                  isPrimary: Value(address.isPrimary),
                ),
              );
        }
        for (final pref in customer.preferences) {
          await db
              .into(db.customerPreferenceTable)
              .insertOnConflictUpdate(
                CustomerPreferenceTableCompanion.insert(
                  customerPreferenceId: Value(pref.id),
                  customerId: Value(customer.id),
                  dayOfWeek: Value(pref.dayOfWeek),
                  timeWindowStart: pref.timeWindowStart,
                  timeWindowEnd: Value(pref.timeWindowEnd),
                ),
              );
        }
        return const Resource.success(null);
      });
    } catch (e) {
      return Resource.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Resource<void>> updateCustomer(Customer customer) async {
    try {
      final existing = await (db.select(db.customerTable)
            ..where((t) => t.customerId.equals(customer.id)))
          .getSingleOrNull();

      if (existing == null) {
        return Resource.error(Exception('Customer not found'));
      }

      return await db.transaction(() async {
        await db
            .into(db.customerTable)
            .insertOnConflictUpdate(
              CustomerTableCompanion.insert(
                customerId: Value(customer.id),
                name: customer.name,
                phone: Value(customer.phone),
              ),
            );

        await (db.delete(db.customerAddressTable)
              ..where((t) => t.customerId.equals(customer.id)))
            .go();
        for (final address in customer.addresses) {
          await db
              .into(db.customerAddressTable)
              .insert(
                CustomerAddressTableCompanion.insert(
                  addressId: Value(address.id),
                  customerId: Value(customer.id),
                  street: Value(address.street),
                  apartment: Value(address.apartment),
                  floor: Value(address.floor),
                  visualReference: Value(address.visualReference),
                  isPrimary: Value(address.isPrimary),
                ),
              );
        }

        await (db.delete(db.customerPreferenceTable)
              ..where((t) => t.customerId.equals(customer.id)))
            .go();
        for (final pref in customer.preferences) {
          await db
              .into(db.customerPreferenceTable)
              .insert(
                CustomerPreferenceTableCompanion.insert(
                  customerPreferenceId: Value(pref.id),
                  customerId: Value(customer.id),
                  dayOfWeek: Value(pref.dayOfWeek),
                  timeWindowStart: pref.timeWindowStart,
                  timeWindowEnd: Value(pref.timeWindowEnd),
                ),
              );
        }
        return const Resource.success(null);
      });
    } catch (e) {
      return Resource.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Resource<void>> deleteCustomer(String customerId) async {
    try {
      return await db.transaction(() async {
        await (db.delete(db.customerPreferenceTable)
              ..where((t) => t.customerId.equals(customerId)))
            .go();
        await (db.delete(db.customerAddressTable)
              ..where((t) => t.customerId.equals(customerId)))
            .go();
        await (db.delete(db.customerTable)
              ..where((t) => t.customerId.equals(customerId)))
            .go();
        return const Resource.success(null);
      });
    } catch (e) {
      return Resource.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Resource<Customer?>> getCustomerById(String id) async {
    try {
      final customerData = await (db.select(db.customerTable)
            ..where((t) => t.customerId.equals(id)))
          .getSingleOrNull();

      if (customerData == null) {
        return const Resource.success(null);
      }

      final addresses = await (db.select(db.customerAddressTable)
            ..where((t) => t.customerId.equals(id)))
          .get();

      final preferences = await (db.select(db.customerPreferenceTable)
            ..where((t) => t.customerId.equals(id)))
          .get();

      final customer = Customer(
        id: customerData.customerId,
        name: customerData.name,
        phone: customerData.phone,
        addresses: addresses
            .map(
              (a) => CustomerAddress(
                id: a.addressId,
                street: a.street,
                apartment: a.apartment,
                floor: a.floor,
                visualReference: a.visualReference,
                isPrimary: a.isPrimary,
              ),
            )
            .toList(),
        preferences: preferences
            .map(
              (p) => CustomerPreference(
                id: p.customerPreferenceId,
                dayOfWeek: p.dayOfWeek,
                timeWindowStart: p.timeWindowStart,
                timeWindowEnd: p.timeWindowEnd,
              ),
            )
            .toList(),
      );

      return Resource.success(customer);
    } catch (e) {
      return Resource.error(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Stream<int> watchCustomerCount() {
    final countExpr = db.customerTable.customerId.count();
    return (db.selectOnly(db.customerTable)..addColumns([countExpr]))
        .map((row) => row.read(countExpr) ?? 0)
        .watchSingle();
  }

  @override
  Stream<List<Customer>> watchAllCustomers() {
    final query = db.select(db.customerTable).join([
      leftOuterJoin(
        db.customerAddressTable,
        db.customerAddressTable.customerId.equalsExp(
          db.customerTable.customerId,
        ),
      ),
      leftOuterJoin(
        db.customerPreferenceTable,
        db.customerPreferenceTable.customerId.equalsExp(
          db.customerTable.customerId,
        ),
      ),
    ]);

    return query.watch().map((rows) {
      final Map<String, Customer> customers = {};
      final Map<String, Set<String>> addressIds = {};
      final Map<String, Set<String>> prefIds = {};

      for (final row in rows) {
        final customerData = row.readTable(db.customerTable);
        final addressData = row.readTableOrNull(db.customerAddressTable);
        final prefData = row.readTableOrNull(db.customerPreferenceTable);

        final cid = customerData.customerId;

        if (!customers.containsKey(cid)) {
          customers[cid] = Customer(
            id: cid,
            name: customerData.name,
            phone: customerData.phone,
            addresses: [],
            preferences: [],
          );
          addressIds[cid] = {};
          prefIds[cid] = {};
        }

        if (addressData != null && !addressIds[cid]!.contains(addressData.addressId)) {
          addressIds[cid]!.add(addressData.addressId);
          customers[cid]!.addresses.add(
            CustomerAddress(
              id: addressData.addressId,
              street: addressData.street,
              apartment: addressData.apartment,
              floor: addressData.floor,
              visualReference: addressData.visualReference,
              isPrimary: addressData.isPrimary,
            ),
          );
        }

        if (prefData != null && !prefIds[cid]!.contains(prefData.customerPreferenceId)) {
          prefIds[cid]!.add(prefData.customerPreferenceId);
          customers[cid]!.preferences.add(
            CustomerPreference(
              id: prefData.customerPreferenceId,
              dayOfWeek: prefData.dayOfWeek,
              timeWindowStart: prefData.timeWindowStart,
              timeWindowEnd: prefData.timeWindowEnd,
            ),
          );
        }
      }

      return customers.values.toList();
    });
  }
}

final driftCustomerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftCustomerRepository(db);
});
