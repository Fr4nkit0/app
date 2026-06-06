import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => DriftPaymentRepository(ref.watch(databaseProvider)),
);
