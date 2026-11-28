import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';

/// Customer accounts that never load: the sale draft keeps each customer's
/// snapshot balance (`Customer.debtAmount`) and no database is opened.
final unloadedCustomerBalances = customerBalanceProvider.overrideWith(
  (ref, id) => const Stream<int>.empty(),
);
