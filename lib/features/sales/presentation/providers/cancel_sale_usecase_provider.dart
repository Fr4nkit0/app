import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/providers/clock_provider.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/sales/domain/usecases/cancel_sale.usecase.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';

final cancelSaleUseCaseProvider = Provider<CancelSaleUseCase>(
  (ref) => CancelSaleUseCase(
    saleRepo: ref.watch(saleRepositoryProvider),
    paymentRepo: ref.watch(paymentRepositoryProvider),
    transaction: ref.watch(transactionRunnerProvider),
    now: ref.watch(clockProvider),
  ),
);
