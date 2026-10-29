import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// Container types, payment methods and visit outcomes, stored by the
/// server's own ids.
class CatalogsApplier implements PullApplier {
  CatalogsApplier(this._db);

  final AppDatabase _db;

  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) => store(rows);

  /// Stores the catalogs of [data], a bootstrap or a pull download.
  Future<void> store(Map<String, Object?> data) async {
    for (final c in jsonList(data['container_types'])) {
      await _db
          .into(_db.containerTypeTable)
          .insertOnConflictUpdate(
            ContainerTypeTableCompanion.insert(
              id: Value(c['id'] as int),
              code: c['code'] as String,
              description: Value(c['description'] as String?),
              enabled: enabledOf(c),
            ),
          );
    }
    for (final p in jsonList(data['payment_methods'])) {
      await _db
          .into(_db.paymentMethodTable)
          .insertOnConflictUpdate(
            PaymentMethodTableCompanion.insert(
              id: Value(p['id'] as int),
              code: p['code'] as String,
              name: p['name'] as String,
              enabled: enabledOf(p),
            ),
          );
    }
    for (final o in jsonList(data['visit_outcomes'])) {
      await _db
          .into(_db.visitOutcomeTable)
          .insertOnConflictUpdate(
            VisitOutcomeTableCompanion.insert(
              id: Value(o['id'] as int),
              code: Value(o['code'] as String?),
              name: o['name'] as String,
              triggersReschedule: Value(o['triggers_reschedule'] == true),
              enabled: enabledOf(o),
            ),
          );
    }
  }
}
