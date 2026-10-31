import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/customer_address.repository.dart';
import 'package:app/features/customers/domain/models/address_details.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:drift/drift.dart';

/// Each write queues one `customer_address` change per address it touched,
/// naming the wire fields it changed ([PendingChange.changedFieldsKey]); the
/// push builds the record from the stored row.
class DriftCustomerAddressRepository implements CustomerAddressRepository {
  DriftCustomerAddressRepository(this._db, {DateTime Function()? now})
    : _queue = DriftPendingChangeRepository(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final PendingChangeRepository _queue;
  final DateTime Function() _now;

  @override
  Stream<List<CustomerAddress>> watchForCustomer(String customerId) =>
      (_db.select(_db.customerAddressTable)
            ..where(
              (t) => t.customerId.equals(customerId) & t.enabled.equals(true),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.isPrimary),
              (t) => OrderingTerm.asc(t.createdAt),
              // Addresses added within the same second keep their order.
              (t) => OrderingTerm.asc(const CustomExpression<int>('rowid')),
            ]))
          .watch()
          .map((rows) => rows.map(_toModel).toList());

  @override
  Future<CustomerAddress?> findEnabled(String addressId) async {
    final row = await _enabledRow(addressId);
    return row == null ? null : _toModel(row);
  }

  @override
  Future<String> add(String customerId, AddressDetails details) async {
    final customer = await (_db.select(
      _db.customerTable,
    )..where((t) => t.customerId.equals(customerId))).getSingleOrNull();
    if (customer == null) throw const NotFoundFailure('customer');

    final primaries =
        await (_db.select(_db.customerAddressTable)..where(
              (t) =>
                  t.customerId.equals(customerId) &
                  t.isPrimary.equals(true) &
                  t.enabled.equals(true),
            ))
            .get();
    final now = _now();
    final row = await _db
        .into(_db.customerAddressTable)
        .insertReturning(
          _fields(details).copyWith(
            customerId: Value(customerId),
            isPrimary: Value(primaries.isEmpty),
            createdAt: Value(now),
            lastModifiedDate: Value(now),
          ),
        );
    await _enqueue(row.addressId, PendingAction.insert, {
      'customerId': customerId,
    });
    return row.addressId;
  }

  /// An edit that changes nothing is neither written nor queued.
  @override
  Future<void> edit(String addressId, AddressDetails details) async {
    final stored = await _enabledRow(addressId);
    if (stored == null) throw const NotFoundFailure('address');
    final changed = [
      for (final (field, before, after) in [
        ('street', stored.street, details.street),
        ('apartment', stored.apartment, details.apartment),
        ('floor', stored.floor, details.floor),
        ('visual_reference', stored.visualReference, details.visualReference),
        ('neighborhood', stored.neighborhood, details.neighborhood),
      ])
        if (before != after) field,
    ];
    if (changed.isEmpty) return;
    await _write(
      addressId,
      _fields(details).copyWith(lastModifiedDate: Value(_now())),
    );
    await _enqueue(addressId, PendingAction.update, {
      PendingChange.changedFieldsKey: changed,
    });
  }

  @override
  Future<void> disable(String addressId) async {
    await _write(
      addressId,
      CustomerAddressTableCompanion(
        enabled: const Value(false),
        lastModifiedDate: Value(_now()),
      ),
    );
    await _enqueue(addressId, PendingAction.update, const {
      'enabled': false,
      PendingChange.changedFieldsKey: ['enabled'],
    });
  }

  /// The previous primary is queued after the new one and dated a second
  /// later: the server unsets it with the new primary's date, so this keeps
  /// its own record newer and any pending edit of it still applies.
  @override
  Future<void> setPrimary(String addressId) async {
    final target = await _enabledRow(addressId);
    if (target == null) throw const NotFoundFailure('address');
    final now = _now();
    await _write(
      addressId,
      CustomerAddressTableCompanion(
        isPrimary: const Value(true),
        lastModifiedDate: Value(now),
      ),
    );
    await _enqueue(addressId, PendingAction.update, const {
      'isPrimary': true,
      PendingChange.changedFieldsKey: ['is_primary'],
    });

    final previous =
        await (_db.select(_db.customerAddressTable)..where(
              (t) =>
                  t.customerId.equals(target.customerId) &
                  t.isPrimary.equals(true) &
                  t.addressId.equals(addressId).not(),
            ))
            .get();
    for (final p in previous) {
      await _write(
        p.addressId,
        CustomerAddressTableCompanion(
          isPrimary: const Value(false),
          lastModifiedDate: Value(now.add(const Duration(seconds: 1))),
        ),
      );
      await _enqueue(p.addressId, PendingAction.update, const {
        'isPrimary': false,
        PendingChange.changedFieldsKey: ['is_primary'],
      });
    }
  }

  Future<CustomerAddressTableData?> _enabledRow(String addressId) =>
      (_db.select(_db.customerAddressTable)..where(
            (t) => t.addressId.equals(addressId) & t.enabled.equals(true),
          ))
          .getSingleOrNull();

  Future<void> _write(String addressId, CustomerAddressTableCompanion fields) =>
      (_db.update(
        _db.customerAddressTable,
      )..where((t) => t.addressId.equals(addressId))).write(fields);

  Future<void> _enqueue(
    String addressId,
    PendingAction action,
    Map<String, dynamic> payload,
  ) => _queue.enqueue(
    entity: PendingEntity.customerAddress,
    entityId: addressId,
    action: action,
    payload: {'addressId': addressId, ...payload},
  );

  static CustomerAddressTableCompanion _fields(AddressDetails d) =>
      CustomerAddressTableCompanion(
        street: Value(d.street),
        neighborhood: Value(d.neighborhood),
        apartment: Value(d.apartment),
        floor: Value(d.floor),
        visualReference: Value(d.visualReference),
      );

  static CustomerAddress _toModel(CustomerAddressTableData a) =>
      CustomerAddress(
        id: a.addressId,
        street: a.street,
        apartment: a.apartment,
        floor: a.floor,
        visualReference: a.visualReference,
        isPrimary: a.isPrimary,
        latitude: a.latitude,
        longitude: a.longitude,
        neighborhood: a.neighborhood,
      );
}
