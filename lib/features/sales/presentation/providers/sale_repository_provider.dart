import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/data/repositories/sale.repository.dart';

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => DriftSaleRepository(ref.watch(databaseProvider)),
);
