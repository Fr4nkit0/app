import 'package:app/core/utils/resource.dart';
import 'package:app/features/sales/domain/models/sale.dart';

abstract class SaleRepository {
  Stream<List<Sale>> watchAllSales();
  Future<Resource<void>> saveSale(Sale sale);
}
