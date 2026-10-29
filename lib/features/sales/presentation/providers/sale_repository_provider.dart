import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/data/repositories/sale.repository.dart';
import 'package:app/features/sales/domain/models/sale.dart';

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => DriftSaleRepository(ref.watch(databaseProvider)),
);

/// The sales registered at a stop, keyed by its id (a sale's visit id).
final stopSalesProvider = StreamProvider.family<List<Sale>, String>(
  (ref, stopId) => ref.watch(saleRepositoryProvider).watchVisitSales(stopId),
);
