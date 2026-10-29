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

  group('default returned containers', () {
    const jug = Product(
      id: 'p3',
      name: 'Jug',
      unitLabel: 'u',
      price: 1500,
      containerType: 'JUG',
    );
    const jugRefill = Product(
      id: 'p4',
      name: 'Jug refill',
      unitLabel: 'u',
      price: 1200,
      containerType: 'JUG',
    );
    const siphon = Product(
      id: 'p5',
      name: 'Siphon',
      unitLabel: 'u',
      price: 900,
      containerType: 'SIPHON',
    );

    Map<String, int> returned() =>
        container.read(saleDraftProvider).returnedContainers;

    test('returned equals delivered for every container type', () {
      notifier().setQuantity(SaleItem(product: jug, quantity: 0), 2);
      notifier().setQuantity(SaleItem(product: jugRefill, quantity: 0), 1);
      notifier().setQuantity(SaleItem(product: siphon, quantity: 0), 4);
      notifier().setQuantity(SaleItem(product: priced, quantity: 0), 5);

      expect(returned(), {'JUG': 3, 'SIPHON': 4});
    });

    test('a container type no longer delivered drops its default return', () {
      notifier().setQuantity(SaleItem(product: jug, quantity: 0), 2);
      notifier().setQuantity(SaleItem(product: siphon, quantity: 0), 1);
      notifier().setQuantity(SaleItem(product: siphon, quantity: 0), 0);

      expect(returned(), {'JUG': 2});
    });

    test('the sale records delivered and returned containers per type', () {
      notifier().setQuantity(SaleItem(product: jug, quantity: 0), 3);
      notifier().setQuantity(SaleItem(product: siphon, quantity: 0), 2);
      notifier().setReturnedQuantity('JUG', 1);

      final movements = container
          .read(saleDraftProvider)
          .toContainerMovements('cust-1', 'visit-1');

      expect(
        {
          for (final m in movements)
            m.containerType: (m.deliveredQuantity, m.returnedQuantity),
        },
        {'JUG': (3, 1), 'SIPHON': (2, 2)},
      );
      expect(movements.map((m) => m.visitId).toSet(), {'visit-1'});
    });
  });
}
