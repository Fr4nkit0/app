import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/clock_provider.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/visits/domain/usecases/edit_visit.usecase.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';

final editVisitUseCaseProvider = Provider<EditVisitUseCase>(
  (ref) => EditVisitUseCase(
    visitRepo: ref.watch(visitRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
    now: ref.watch(clockProvider),
  ),
);
