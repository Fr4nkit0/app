import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/visits/data/repositories/drift_visit.repository.dart';
import 'package:app/features/visits/data/repositories/visit.repository.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';

final visitRepositoryProvider = Provider<VisitRepository>(
  (ref) => DriftVisitRepository(ref.watch(databaseProvider)),
);

final visitOutcomesProvider = StreamProvider<List<VisitOutcome>>(
  (ref) => ref.watch(visitRepositoryProvider).watchOutcomes(),
);
