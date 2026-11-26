import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/balance_corrections/data/repositories/balance_correction.repository.dart';
import 'package:app/features/balance_corrections/domain/usecases/correct_balance.usecase.dart';

/// Where balance corrections are stored, moved and queued.
final balanceCorrectionRepositoryProvider =
    Provider<BalanceCorrectionRepository>(
      (ref) => DriftBalanceCorrectionRepository(ref.watch(databaseProvider)),
    );

final correctBalanceUseCaseProvider = Provider<CorrectBalanceUseCase>(
  (ref) => CorrectBalanceUseCase(
    repo: ref.watch(balanceCorrectionRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);
