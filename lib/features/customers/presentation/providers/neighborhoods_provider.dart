import 'package:app/features/customers/data/repositories/drift.neighborhood.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The neighborhood names the address picker offers.
final neighborhoodNamesProvider = StreamProvider.autoDispose<List<String>>(
  (ref) => ref.watch(driftNeighborhoodRepositoryProvider).watchNames(),
);
