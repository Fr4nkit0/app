import 'package:app/features/sales/domain/models/sale.dart';

abstract class SaleRepository {
  /// The sales made during the visit [visitId] (the stop's id).
  Stream<List<Sale>> watchVisitSales(String visitId);

  /// Writes the sale, its items, its account entry, the customer balance and
  /// its pending change; run it inside the use case's unit of work.
  Future<void> saveSale(Sale sale);

  /// The sale [saleId], cancelled or not; null when it does not exist.
  Future<Sale?> findSale(String saleId);

  /// What [customerId] owes now (positive) or has in favor (negative), as
  /// the customer account holds it; 0 while they have no account. Read it
  /// inside the use case's unit of work to check against the balance the
  /// write will move.
  Future<double> customerBalanceOf(String customerId);

  /// Marks [sale] cancelled at [at], books its credit note, takes it out of
  /// the customer balance, returns its stock to the truck and, unless
  /// [queue] is false (the server already holds the cancellation), queues
  /// the cancellation; run it inside the use case's unit of work.
  Future<void> cancelSale(
    Sale sale, {
    required DateTime at,
    String? reason,
    bool queue = true,
  });
}
