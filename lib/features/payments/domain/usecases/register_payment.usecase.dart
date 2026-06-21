import 'package:app/core/utils/resource.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';

class RegisterPaymentUseCase {
  const RegisterPaymentUseCase({required PaymentRepository paymentRepo})
    : _paymentRepo = paymentRepo;

  final PaymentRepository _paymentRepo;

  Future<Resource<void>> execute(List<Payment> payments) async {
    if (payments.isEmpty) {
      return Resource.error(Exception('No payments provided'));
    }
    for (final payment in payments) {
      if (payment.amount <= 0) {
        return Resource.error(Exception('Payment amount must be greater than 0'));
      }
    }
    try {
      await _paymentRepo.recordPayments(payments);
      return const Resource.success(null);
    } on Exception catch (e) {
      return Resource.error(e);
    }
  }
}
