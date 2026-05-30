import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/sales/data/repositories/mock_sale_repository.dart';
import 'package:app/features/sales/data/repositories/sale.repository.dart';

final saleRepositoryProvider =
    Provider<SaleRepository>((ref) => MockSaleRepository());
