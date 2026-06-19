import 'package:app/core/utils/resource.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';

class RegisterPaymentUseCase {
  const RegisterPaymentUseCase({required PaymentRepository paymentRepo})
    : _paymentRepo = paymentRepo;

  final PaymentRepository _paymentRepo;

  Future<Resource<void>> execute(Payment payment) async {
    if (payment.amount <= 0) {
      return Resource.error(Exception('Payment amount must be greater than 0'));
    }
    try {
      await _paymentRepo.recordPayment(payment);
      return const Resource.success(null);
    } on Exception catch (e) {
      return Resource.error(e);
    }
  }
}
