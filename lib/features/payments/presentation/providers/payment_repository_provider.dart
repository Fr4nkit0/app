import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/usecases/register_payment.usecase.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => DriftPaymentRepository(ref.watch(databaseProvider)),
);

final registerPaymentUseCaseProvider = Provider<RegisterPaymentUseCase>(
  (ref) => RegisterPaymentUseCase(paymentRepo: ref.watch(paymentRepositoryProvider)),
);
