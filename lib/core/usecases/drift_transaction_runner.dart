import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/transaction_runner.dart';

/// The [TransactionRunner] over a Drift transaction of [db]: any throw rolls
/// every write back; a [DomainFailure] is rethrown unchanged and anything
/// else surfaces as a [StorageFailure].
TransactionRunner driftTransactionRunner(GeneratedDatabase db) =>
    <T>(Future<T> Function() action) async {
      try {
        return await db.transaction(action);
      } on DomainFailure {
        rethrow;
      } catch (e, stackTrace) {
        Error.throwWithStackTrace(StorageFailure(e), stackTrace);
      }
    };

/// The unit of work every use case provider runs its writes in.
final transactionRunnerProvider = Provider<TransactionRunner>(
  (ref) => driftTransactionRunner(ref.watch(databaseProvider)),
);
