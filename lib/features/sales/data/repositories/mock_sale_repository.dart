import 'dart:async';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/sales/data/repositories/sale.repository.dart';
import 'package:app/features/sales/domain/models/sale.dart';

class MockSaleRepository implements SaleRepository {
  MockSaleRepository() {
    _controller = StreamController<List<Sale>>.broadcast();
  }

  final List<Sale> _sales = [];
  late StreamController<List<Sale>> _controller;

  @override
  Stream<List<Sale>> watchAllSales() async* {
    yield List.of(_sales);
    yield* _controller.stream;
  }

  @override
  Future<Resource<void>> saveSale(Sale sale) async {
    _sales.insert(0, sale);
    _controller.add(List.of(_sales));
    return const Resource.success(null);
  }
}
