import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';

void main() {
  const priced = Product(
    id: 'p1',
    name: 'Agua 20L',
    unitLabel: 'bidón',
    price: 1500,
  );
  const unpriced = Product(
    id: 'p2',
    name: 'Soda',
    unitLabel: 'u',
    price: 0,
  );

  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  SaleDraft notifier() => container.read(saleDraftProvider.notifier);
  int qtyOf(String id) => container
      .read(saleDraftProvider)
      .items
      .where((i) => i.product.id == id)
      .fold(0, (s, i) => s + i.quantity);

  test('setQuantity sets, clamps to 999 and removes at zero', () {
    notifier().setQuantity(SaleItem(product: priced, quantity: 0), 12);
    expect(qtyOf('p1'), 12);

    notifier().setQuantity(SaleItem(product: priced, quantity: 0), 5000);
    expect(qtyOf('p1'), 999);

    notifier().setQuantity(SaleItem(product: priced, quantity: 0), 0);
    expect(container.read(saleDraftProvider).items, isEmpty);
  });

  test('setQuantity ignores a product without price', () {
    notifier().setQuantity(SaleItem(product: unpriced, quantity: 0), 4);
    expect(container.read(saleDraftProvider).items, isEmpty);
  });
}
