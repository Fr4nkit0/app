import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/customer_preference.repository.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:drift/drift.dart';

/// Each write queues one `customer_preference` change; the push rebuilds
/// the record from the stored row.
class DriftCustomerPreferenceRepository
    implements CustomerPreferenceRepository {
  DriftCustomerPreferenceRepository(this._db, {DateTime Function()? now})
    : _queue = DriftPendingChangeRepository(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final PendingChangeRepository _queue;
  final DateTime Function() _now;

  @override
  Stream<List<CustomerPreference>> watchForCustomer(String customerId) =>
      (_db.select(_db.customerPreferenceTable)
            ..where(
              (t) => t.customerId.equals(customerId) & t.enabled.equals(true),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.dayOfWeek),
              (t) => OrderingTerm.asc(t.timeWindowStart),
            ]))
          .watch()
          .map((rows) => rows.map(toModel).toList());

  @override
  Future<({CustomerPreference preference, String customerId})?> findEnabled(
    String preferenceId,
  ) async {
    final row =
        await (_db.select(_db.customerPreferenceTable)..where(
              (t) =>
                  t.customerPreferenceId.equals(preferenceId) &
                  t.enabled.equals(true),
            ))
            .getSingleOrNull();
    return row == null
        ? null
        : (preference: toModel(row), customerId: row.customerId);
  }

  /// Pulled rows may still carry `HH:mm:ss`, so starts are compared as
  /// times rather than as text.
  @override
  Future<({String id, bool enabled})?> findInSlot(
    String customerId,
    PreferenceDetails details, {
    String? exceptId,
  }) async {
    final rows =
        await (_db.select(_db.customerPreferenceTable)..where(
              (t) =>
                  t.customerId.equals(customerId) &
                  t.dayOfWeek.equals(details.dayOfWeek),
            ))
            .get();
    for (final r in rows) {
      if (r.customerPreferenceId != exceptId &&
          details.sameSlot(r.dayOfWeek, r.timeWindowStart)) {
        return (id: r.customerPreferenceId, enabled: r.enabled);
      }
    }
    return null;
  }

  @override
  Future<String> add(String customerId, PreferenceDetails details) async {
    final customer = await (_db.select(
      _db.customerTable,
    )..where((t) => t.customerId.equals(customerId))).getSingleOrNull();
    if (customer == null) throw const NotFoundFailure('customer');

    final now = _now();
    final row = await _db
        .into(_db.customerPreferenceTable)
        .insertReturning(
          _fields(details).copyWith(
            customerId: Value(customerId),
            createdAt: Value(now),
            lastModifiedDate: Value(now),
          ),
        );
    await _enqueue(row.customerPreferenceId, PendingAction.insert, {
      'customerId': customerId,
    });
    return row.customerPreferenceId;
  }

  @override
  Future<void> edit(String preferenceId, PreferenceDetails details) async {
    await _write(
      preferenceId,
      _fields(details).copyWith(lastModifiedDate: Value(_now())),
    );
    await _enqueue(preferenceId, PendingAction.update, const {});
  }

  @override
  Future<void> enable(String preferenceId, PreferenceDetails details) async {
    await _write(
      preferenceId,
      _fields(
        details,
      ).copyWith(enabled: const Value(true), lastModifiedDate: Value(_now())),
    );
    await _enqueue(preferenceId, PendingAction.update, const {'enabled': true});
  }

  @override
  Future<void> disable(String preferenceId) async {
    await _write(
      preferenceId,
      CustomerPreferenceTableCompanion(
        enabled: const Value(false),
        lastModifiedDate: Value(_now()),
      ),
    );
    await _enqueue(preferenceId, PendingAction.update, const {
      'enabled': false,
    });
  }

  Future<void> _write(
    String preferenceId,
    CustomerPreferenceTableCompanion fields,
  ) => (_db.update(
    _db.customerPreferenceTable,
  )..where((t) => t.customerPreferenceId.equals(preferenceId))).write(fields);

  Future<void> _enqueue(
    String preferenceId,
    PendingAction action,
    Map<String, dynamic> payload,
  ) => _queue.enqueue(
    entity: PendingEntity.customerPreference,
    entityId: preferenceId,
    action: action,
    payload: {'preferenceId': preferenceId, ...payload},
  );

  static CustomerPreferenceTableCompanion _fields(PreferenceDetails d) =>
      CustomerPreferenceTableCompanion(
        dayOfWeek: Value(d.dayOfWeek),
        timeWindowStart: Value(d.start),
        timeWindowEnd: Value(d.end),
      );

  static CustomerPreference toModel(CustomerPreferenceTableData p) =>
      CustomerPreference(
        id: p.customerPreferenceId,
        dayOfWeek: p.dayOfWeek,
        timeWindowStart: p.timeWindowStart,
        timeWindowEnd: p.timeWindowEnd,
      );
}
