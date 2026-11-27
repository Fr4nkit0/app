import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';

Product _product(int price, {String? agreementUuid}) => Product(
  id: 'p-1',
  name: 'Bidón 20L',
  unitLabel: 'bidón',
  price: price,
  agreementUuid: agreementUuid,
);

void main() {
  late ProviderContainer container;
  SaleDraft draft() => container.read(saleDraftProvider.notifier);

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    draft().selectCustomer(
      Customer(
        id: 'c-1',
        name: 'Kiosco Norte',
        addresses: const [],
        preferences: const [],
      ),
    );
    draft().setQuantity(
      SaleItem(product: _product(5000, agreementUuid: 'a-1'), quantity: 0),
      2,
    );
  });

  test('a line whose product is left without a price leaves the sale', () {
    // Its agreement was deleted and the product has no list price.
    draft().repriceItems([_product(0)]);

    final state = container.read(saleDraftProvider);
    expect(state.items, isEmpty);
    expect(state.total, 0);
    expect(state.customer!.id, 'c-1');
  });

  test('a line whose product is not in the list keeps its price', () {
    draft().repriceItems(const []);

    final state = container.read(saleDraftProvider);
    expect(state.items.single.quantity, 2);
    expect(state.total, 10000);
  });
}
