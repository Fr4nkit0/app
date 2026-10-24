import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/visits/domain/usecases/complete_visit.usecase.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';

final completeVisitUseCaseProvider = Provider<CompleteVisitUseCase>(
  (ref) => CompleteVisitUseCase(
    routeRepo: ref.watch(routeRepositoryProvider),
    visitRepo: ref.watch(visitRepositoryProvider),
    // The visit and its reschedule are queued atomically, so one push
    // always carries both.
    transaction: ref.watch(databaseProvider).transaction,
  ),
);
