import 'package:app/features/sales/domain/models/sale.dart';

abstract class SaleRepository {
  /// The sales made during the visit [visitId] (the stop's id).
  Stream<List<Sale>> watchVisitSales(String visitId);

  /// Writes the sale, its items, its account entry, the customer balance and
  /// its pending change; run it inside the use case's unit of work.
  Future<void> saveSale(Sale sale);

  /// The sale [saleId], cancelled or not; null when it does not exist.
  Future<Sale?> findSale(String saleId);

  /// Marks [sale] cancelled at [at], books its credit note, takes it out of
  /// the customer balance, returns its stock to the truck and queues the
  /// cancellation; run it inside the use case's unit of work.
  Future<void> cancelSale(Sale sale, {required DateTime at, String? reason});
}
