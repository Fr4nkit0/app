import 'package:app/features/payments/data/repositories/customer_account.dart';

export 'package:app/features/payments/data/repositories/customer_account.dart';

/// The former name of [CustomerAccount], still used by the sale and payment
/// pushers; remove it once they name [CustomerAccount] directly.
typedef CustomerBalanceStore = CustomerAccount;

/// The former name of [CustomerAccount.post] for the same callers.
extension CustomerBalanceStoreAdjust on CustomerAccount {
  Future<void> adjust(String customerId, double delta, {String? lastEntryId}) =>
      post(customerId, delta, lastEntryId: lastEntryId);
}
