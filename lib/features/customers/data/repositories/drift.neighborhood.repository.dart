import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/neighborhood.repository.dart';
import 'package:app/features/customers/domain/models/salta_neighborhoods.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriftNeighborhoodRepository implements NeighborhoodRepository {
  DriftNeighborhoodRepository(this.db);

  final AppDatabase db;

  @override
  Stream<List<String>> watchNames() {
    // Disabled rows are read too: they tell a synced catalog apart from one
    // that was never downloaded.
    final query = db.select(db.neighborhoodTable)
      ..orderBy([(t) => OrderingTerm.asc(t.name.collate(Collate.noCase))]);
    return query.watch().map(
      (rows) => rows.isEmpty
          ? saltaNeighborhoods
          : [
              for (final row in rows)
                if (row.enabled) row.name,
            ],
    );
  }
}

final driftNeighborhoodRepositoryProvider = Provider<NeighborhoodRepository>(
  (ref) => DriftNeighborhoodRepository(ref.watch(databaseProvider)),
);
