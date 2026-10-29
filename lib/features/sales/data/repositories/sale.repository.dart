import 'package:app/features/sales/domain/models/sale.dart';

abstract class SaleRepository {
  /// The sales made during the visit [visitId] (the stop's id).
  Stream<List<Sale>> watchVisitSales(String visitId);

  /// Writes the sale, its items, its account entry, the customer balance and
  /// its pending change; run it inside the use case's unit of work.
  Future<void> saveSale(Sale sale);
}
