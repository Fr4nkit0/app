import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/utils/string_utils.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer_edit.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/payments/data/repositories/customer_account.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/data/repositories/removed_customers.dart';
import 'package:app/features/sync/data/repositories/server_shadow.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriftCustomerRepository implements CustomerRepository {
  final AppDatabase db;
  final PendingChangeRepository _queue;
  final ServerShadow _shadow;
  final CustomerAccount _account;

  DriftCustomerRepository(this.db)
    : _queue = DriftPendingChangeRepository(db),
      _shadow = ServerShadow(db),
      _account = CustomerAccount(db);

  static Map<String, dynamic> _payload(Customer customer) => {
    'customerId': customer.id,
    'name': customer.name,
    'phone': customer.phone,
    'addresses': [
      for (final a in customer.addresses)
        {
          'addressId': a.id,
          'street': a.street,
          'apartment': a.apartment,
          'floor': a.floor,
          'visualReference': a.visualReference,
          'isPrimary': a.isPrimary,
          'latitude': a.latitude,
          'longitude': a.longitude,
          'neighborhood': a.neighborhood,
        },
    ],
    'preferences': [
      for (final p in customer.preferences)
        {
          'preferenceId': p.id,
          'dayOfWeek': p.dayOfWeek,
          'timeWindowStart': p.timeWindowStart,
          'timeWindowEnd': p.timeWindowEnd,
        },
    ],
  };

  /// What the customer push carries for [customerId], keyed by the wire
  /// names its edits record ([PendingChange.changedFieldsKey]); null when
  /// the customer does not exist.
  Future<Map<String, Object?>?> _wireValues(String customerId) async {
    final customer = await (db.select(
      db.customerTable,
    )..where((t) => t.customerId.equals(customerId))).getSingleOrNull();
    if (customer == null) return null;
    final address = await _pushedAddress(customerId);
    return {
      'name': customer.name,
      'phone_number': customer.phone,
      'enabled': customer.enabled,
      _addressUuid: address?.addressId,
      'address.street': address?.street,
      'address.apartment': address?.apartment,
      'address.floor': address?.floor,
      'address.visual_reference': address?.visualReference,
      'address.neighborhood': address?.neighborhood,
      'address.latitude': address?.latitude,
      'address.longitude': address?.longitude,
    };
  }

  static const _addressUuid = 'address.uuid';

  /// The wire fields that differ between [before] and [after]. When the
  /// pushed address itself changed, every address field differs: the
  /// server's copy holds the other address.
  static List<String> _changedFields(
    Map<String, Object?> before,
    Map<String, Object?> after,
  ) {
    final addressMoved = before[_addressUuid] != after[_addressUuid];
    return [
      for (final MapEntry(:key, :value) in after.entries)
        if (key != _addressUuid &&
            (before[key] != value ||
                (addressMoved && key.startsWith('address.'))))
          key,
    ];
  }

  @override
  Future<void> saveCustomer(Customer customer) async {
    final before = await _wireValues(customer.id);
    final existed = before != null;
    if (existed) {
      await _shadow.captureBeforeEdit(PendingEntity.customer, customer.id);
    }
    await db
        .into(db.customerTable)
        .insertOnConflictUpdate(
          CustomerTableCompanion.insert(
            customerId: Value(customer.id),
            name: customer.name,
            phone: Value(customer.phone),
            lastModifiedDate: Value(DateTime.now()),
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
              latitude: Value(address.latitude),
              longitude: Value(address.longitude),
              neighborhood: Value(address.neighborhood),
              lastModifiedDate: Value(DateTime.now()),
            ),
          );
    }
    final storedPreferences = {
      for (final p in await (db.select(
        db.customerPreferenceTable,
      )..where((t) => t.customerId.equals(customer.id))).get())
        p.customerPreferenceId,
    };
    for (final pref in customer.preferences) {
      if (storedPreferences.contains(pref.id)) {
        await _shadow.captureBeforeEdit(
          PendingEntity.customerPreference,
          pref.id,
        );
      }
      await db
          .into(db.customerPreferenceTable)
          .insertOnConflictUpdate(
            CustomerPreferenceTableCompanion.insert(
              customerPreferenceId: Value(pref.id),
              customerId: Value(customer.id),
              dayOfWeek: Value(pref.dayOfWeek),
              timeWindowStart: pref.timeWindowStart,
              timeWindowEnd: Value(pref.timeWindowEnd),
              lastModifiedDate: Value(DateTime.now()),
            ),
          );
    }
    await _queue.enqueue(
      entity: PendingEntity.customer,
      entityId: customer.id,
      action: existed ? PendingAction.update : PendingAction.insert,
      payload: {
        ..._payload(customer),
        if (existed)
          PendingChange.changedFieldsKey: _changedFields(
            before,
            (await _wireValues(customer.id))!,
          ),
      },
    );
    // Preferences travel on their own, after the customer they belong to.
    for (final pref in customer.preferences) {
      await _queue.enqueue(
        entity: PendingEntity.customerPreference,
        entityId: pref.id,
        action: storedPreferences.contains(pref.id)
            ? PendingAction.update
            : PendingAction.insert,
        payload: {'preferenceId': pref.id, 'customerId': customer.id},
      );
    }
  }

  /// The address is edited in place, keeping its id and server id, so the
  /// pull keeps it linked instead of adding a second one. Preferences, other
  /// addresses and coordinates are left as they are: they do not travel.
  ///
  /// The queued change names the fields that differ from the stored ones,
  /// and an edit that changes nothing is neither written nor queued.
  @override
  Future<void> editCustomer(CustomerEdit edit) async {
    final before = await _wireValues(edit.customerId);
    if (before == null) throw const NotFoundFailure('customer');
    final changed = _changedFields(before, {
      ...before,
      'name': edit.name,
      'phone_number': edit.phone,
      'address.street': edit.street,
      'address.apartment': edit.apartment,
      'address.floor': edit.floor,
      'address.visual_reference': edit.visualReference,
      'address.neighborhood': edit.neighborhood,
    });
    if (changed.isEmpty) return;

    await _shadow.captureBeforeEdit(PendingEntity.customer, edit.customerId);
    final now = DateTime.now();
    final updated =
        await (db.update(
          db.customerTable,
        )..where((t) => t.customerId.equals(edit.customerId))).write(
          CustomerTableCompanion(
            name: Value(edit.name),
            phone: Value(edit.phone),
            lastModifiedDate: Value(now),
          ),
        );
    if (updated == 0) throw const NotFoundFailure('customer');

    final fields = CustomerAddressTableCompanion(
      street: Value(edit.street),
      neighborhood: Value(edit.neighborhood),
      apartment: Value(edit.apartment),
      floor: Value(edit.floor),
      visualReference: Value(edit.visualReference),
      lastModifiedDate: Value(now),
    );
    final address = await _pushedAddress(edit.customerId);
    if (address == null) {
      await db
          .into(db.customerAddressTable)
          .insert(
            fields.copyWith(
              customerId: Value(edit.customerId),
              isPrimary: const Value(true),
            ),
          );
    } else {
      await (db.update(
        db.customerAddressTable,
      )..where((t) => t.addressId.equals(address.addressId))).write(fields);
    }

    await _queue.enqueue(
      entity: PendingEntity.customer,
      entityId: edit.customerId,
      action: PendingAction.update,
      payload: {
        'customerId': edit.customerId,
        'name': edit.name,
        'phone': edit.phone,
        'address': {
          'street': edit.street,
          'neighborhood': edit.neighborhood,
          'apartment': edit.apartment,
          'floor': edit.floor,
          'visualReference': edit.visualReference,
        },
        PendingChange.changedFieldsKey: changed,
      },
    );
  }

  /// Only the office re-enables a customer, so this goes one way.
  @override
  Future<void> disableCustomer(String customerId) async {
    final stored = await (db.select(
      db.customerTable,
    )..where((t) => t.customerId.equals(customerId))).getSingleOrNull();
    if (stored == null) throw const NotFoundFailure('customer');
    if (!stored.enabled) return;

    await _shadow.captureBeforeEdit(PendingEntity.customer, customerId);
    final updated =
        await (db.update(
          db.customerTable,
        )..where((t) => t.customerId.equals(customerId))).write(
          CustomerTableCompanion(
            enabled: const Value(false),
            lastModifiedDate: Value(DateTime.now()),
          ),
        );
    if (updated == 0) throw const NotFoundFailure('customer');

    await _queue.enqueue(
      entity: PendingEntity.customer,
      entityId: customerId,
      action: PendingAction.update,
      payload: {
        'customerId': customerId,
        'enabled': false,
        PendingChange.changedFieldsKey: const ['enabled'],
      },
    );
  }

  /// The address the customer push sends: same selection and order as
  /// `CustomerPusher`.
  Future<CustomerAddressTableData?> _pushedAddress(String customerId) async =>
      (await (db.select(db.customerAddressTable)
                ..where(
                  (t) =>
                      t.customerId.equals(customerId) & t.enabled.equals(true),
                )
                ..orderBy([
                  (t) => OrderingTerm.desc(t.isPrimary),
                  (t) => OrderingTerm.asc(t.createdAt),
                ])
                ..limit(1))
              .get())
          .firstOrNull;

  /// Customers Clientes and the sales picker list: enabled and not
  /// reassigned to another driver ([RemovedCustomers]).
  Expression<bool> _listed($CustomerTableTable t) =>
      t.enabled.equals(true) & RemovedCustomers.isShown(db, t.customerId);

  @override
  Future<Customer?> getCustomerById(String id) async {
    final customerData = await (db.select(
      db.customerTable,
    )..where((t) => t.customerId.equals(id))).getSingleOrNull();

    if (customerData == null) return null;

    final addresses = await (db.select(
      db.customerAddressTable,
    )..where((t) => t.customerId.equals(id))).get();

    final preferences = await (db.select(
      db.customerPreferenceTable,
    )..where((t) => t.customerId.equals(id))).get();

    final debtAmount = await _account.balanceOf(id);

    final customer = Customer(
      id: customerData.customerId,
      name: customerData.name,
      phone: customerData.phone,
      debtAmount: debtAmount,
      addresses: addresses
          .map(
            (a) => CustomerAddress(
              id: a.addressId,
              street: a.street,
              apartment: a.apartment,
              floor: a.floor,
              visualReference: a.visualReference,
              isPrimary: a.isPrimary,
              latitude: a.latitude,
              longitude: a.longitude,
              neighborhood: a.neighborhood,
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

    return customer;
  }

  @override
  Future<List<Customer>> getCustomersPage({
    required int page,
    required int pageSize,
  }) async {
    final offset = page * pageSize;
    final customerRows =
        await (db.select(db.customerTable)
              ..where(_listed)
              ..limit(pageSize, offset: offset))
            .get();

    if (customerRows.isEmpty) return [];

    final customerIds = customerRows.map((c) => c.customerId).toList();

    final addresses =
        await (db.select(db.customerAddressTable)..where(
              (t) => t.customerId.isIn(customerIds) & t.enabled.equals(true),
            ))
            .get();

    final preferences =
        await (db.select(db.customerPreferenceTable)..where(
              (t) => t.customerId.isIn(customerIds) & t.enabled.equals(true),
            ))
            .get();

    final balanceMap = await _account.balancesOf(customerIds);

    final addrMap = <String, List<CustomerAddressTableData>>{};
    for (final a in addresses) {
      addrMap.putIfAbsent(a.customerId, () => []).add(a);
    }

    final prefMap = <String, List<CustomerPreferenceTableData>>{};
    for (final p in preferences) {
      prefMap.putIfAbsent(p.customerId, () => []).add(p);
    }

    return customerRows.map((row) {
      final cid = row.customerId;
      return Customer(
        id: cid,
        name: row.name,
        phone: row.phone,
        debtAmount: balanceMap[cid] ?? 0.0,
        addresses: (addrMap[cid] ?? [])
            .map(
              (a) => CustomerAddress(
                id: a.addressId,
                street: a.street,
                apartment: a.apartment,
                floor: a.floor,
                visualReference: a.visualReference,
                isPrimary: a.isPrimary,
                latitude: a.latitude,
                longitude: a.longitude,
                neighborhood: a.neighborhood,
              ),
            )
            .toList(),
        preferences: (prefMap[cid] ?? [])
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
    }).toList();
  }

  Future<List<Customer>> _getAllCustomers() async {
    final customerRows = await (db.select(
      db.customerTable,
    )..where(_listed)).get();

    if (customerRows.isEmpty) return [];

    final customerIds = customerRows.map((c) => c.customerId).toList();

    final addresses =
        await (db.select(db.customerAddressTable)..where(
              (t) => t.customerId.isIn(customerIds) & t.enabled.equals(true),
            ))
            .get();

    final preferences =
        await (db.select(db.customerPreferenceTable)..where(
              (t) => t.customerId.isIn(customerIds) & t.enabled.equals(true),
            ))
            .get();

    final balanceMap = await _account.balancesOf(customerIds);

    final addrMap = <String, List<CustomerAddressTableData>>{};
    for (final a in addresses) {
      addrMap.putIfAbsent(a.customerId, () => []).add(a);
    }

    final prefMap = <String, List<CustomerPreferenceTableData>>{};
    for (final p in preferences) {
      prefMap.putIfAbsent(p.customerId, () => []).add(p);
    }

    return customerRows.map((row) {
      final cid = row.customerId;
      return Customer(
        id: cid,
        name: row.name,
        phone: row.phone,
        debtAmount: balanceMap[cid] ?? 0.0,
        addresses: (addrMap[cid] ?? [])
            .map(
              (a) => CustomerAddress(
                id: a.addressId,
                street: a.street,
                apartment: a.apartment,
                floor: a.floor,
                visualReference: a.visualReference,
                isPrimary: a.isPrimary,
                latitude: a.latitude,
                longitude: a.longitude,
                neighborhood: a.neighborhood,
              ),
            )
            .toList(),
        preferences: (prefMap[cid] ?? [])
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
    }).toList();
  }

  @override
  Future<List<Customer>> searchCustomers({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    final allCustomers = await _getAllCustomers();
    if (query.isEmpty) {
      final start = page * pageSize;
      if (start >= allCustomers.length) return [];
      final end = (start + pageSize) < allCustomers.length
          ? (start + pageSize)
          : allCustomers.length;
      return allCustomers.sublist(start, end);
    }

    final filtered = allCustomers.where((customer) {
      final addressesStr = customer.addresses
          .map((a) => '${a.street ?? ''} ${a.neighborhood ?? ''}')
          .join(' ');
      final target = '${customer.name} ${customer.phone ?? ''} $addressesStr';
      return StringUtils.fuzzyMatch(query, target);
    }).toList();

    final start = page * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize) < filtered.length
        ? (start + pageSize)
        : filtered.length;
    return filtered.sublist(start, end);
  }

  @override
  Stream<int> watchCustomerCount() {
    final countExpr = db.customerTable.customerId.count();
    return (db.selectOnly(db.customerTable)
          ..addColumns([countExpr])
          ..where(_listed(db.customerTable)))
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
            ) &
            db.customerAddressTable.enabled.equals(true),
      ),
      leftOuterJoin(
        db.customerPreferenceTable,
        db.customerPreferenceTable.customerId.equalsExp(
              db.customerTable.customerId,
            ) &
            db.customerPreferenceTable.enabled.equals(true),
      ),
      _account.balanceJoin(db.customerTable.customerId),
    ])..where(_listed(db.customerTable));

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
            debtAmount: _account.balanceIn(row),
            addresses: [],
            preferences: [],
          );
          addressIds[cid] = {};
          prefIds[cid] = {};
        }

        if (addressData != null &&
            !addressIds[cid]!.contains(addressData.addressId)) {
          addressIds[cid]!.add(addressData.addressId);
          customers[cid]!.addresses.add(
            CustomerAddress(
              id: addressData.addressId,
              street: addressData.street,
              apartment: addressData.apartment,
              floor: addressData.floor,
              visualReference: addressData.visualReference,
              isPrimary: addressData.isPrimary,
              latitude: addressData.latitude,
              longitude: addressData.longitude,
              neighborhood: addressData.neighborhood,
            ),
          );
        }

        if (prefData != null &&
            !prefIds[cid]!.contains(prefData.customerPreferenceId)) {
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
