import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/usecases/register_debt_payment.usecase.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => DriftPaymentRepository(ref.watch(databaseProvider)),
);

final registerDebtPaymentUseCaseProvider = Provider<RegisterDebtPaymentUseCase>(
  (ref) => RegisterDebtPaymentUseCase(
    paymentRepo: ref.watch(paymentRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
  ),
);

final customerBalanceProvider = StreamProvider.family<double, String>((
  ref,
  customerId,
) {
  return ref.watch(paymentRepositoryProvider).watchCustomerBalance(customerId);
});

/// The payments recorded during the visit to a stop, keyed by its id.
final visitPaymentsProvider = StreamProvider.family<List<Payment>, String>(
  (ref, stopId) =>
      ref.watch(paymentRepositoryProvider).watchVisitPayments(stopId),
);
