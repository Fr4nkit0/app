import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import '../../../../support/customer_balances.dart';

void main() {
  const siphon = Product(
    id: 'p1',
    name: 'Soda',
    unitLabel: 'u',
    price: 900,
    containerType: 'SIFON_2L',
  );
  final customer = Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  );

  late ProviderContainer container;
  setUp(
    () => container = ProviderContainer(
      overrides: [unloadedCustomerBalances],
    ),
  );
  tearDown(() => container.dispose());

  SaleDraft notifier() => container.read(saleDraftProvider.notifier);

  test('the skeleton code is ESQUELETO', () {
    expect(ContainerType.skeletonCode, 'ESQUELETO');
  });

  test('a new draft moves no skeleton', () {
    final draft = container.read(saleDraftProvider);
    expect(draft.skeletonDelivered, 0);
    expect(draft.skeletonReturned, 0);
  });

  test('skeleton quantities are set and clamped to 0..999', () {
    notifier().setSkeletonDelivered(2);
    notifier().setSkeletonReturned(5000);
    var draft = container.read(saleDraftProvider);
    expect(draft.skeletonDelivered, 2);
    expect(draft.skeletonReturned, 999);

    notifier().setSkeletonDelivered(-1);
    draft = container.read(saleDraftProvider);
    expect(draft.skeletonDelivered, 0);
  });

  test('returning is not capped by the balance the customer holds', () {
    notifier().selectCustomer(customer);
    notifier().setSkeletonReturned(3);
    expect(container.read(saleDraftProvider).skeletonReturned, 3);
  });

  test('changing a line keeps the skeleton quantities', () {
    notifier().setSkeletonDelivered(1);
    notifier().setSkeletonReturned(1);
    notifier().setQuantity(SaleItem(product: siphon, quantity: 0), 6);

    final draft = container.read(saleDraftProvider);
    expect(draft.skeletonDelivered, 1);
    expect(draft.skeletonReturned, 1);
    expect(draft.returnedContainers, {'SIFON_2L': 6});
  });

  test('clearing the customer clears the skeleton', () {
    notifier().selectCustomer(customer);
    notifier().setSkeletonDelivered(1);
    notifier().setSkeletonReturned(2);
    notifier().clearCustomer();

    final draft = container.read(saleDraftProvider);
    expect(draft.skeletonDelivered, 0);
    expect(draft.skeletonReturned, 0);
  });

  group('toContainerMovements', () {
    test('adds one ESQUELETO movement next to the product containers', () {
      notifier().setQuantity(SaleItem(product: siphon, quantity: 0), 6);
      notifier().setSkeletonDelivered(1);
      notifier().setSkeletonReturned(2);

      final movements = container
          .read(saleDraftProvider)
          .toContainerMovements('c-1', 'v-1');

      expect(movements.map((m) => m.containerType), ['SIFON_2L', 'ESQUELETO']);
      final skeleton = movements.last;
      expect(skeleton.deliveredQuantity, 1);
      expect(skeleton.returnedQuantity, 2);
      expect(skeleton.customerId, 'c-1');
      expect(skeleton.visitId, 'v-1');
      // The siphon keeps the quantity sold, untouched by the skeleton.
      expect(movements.first.deliveredQuantity, 6);
      expect(movements.first.returnedQuantity, 6);
    });

    test('a return-only skeleton is its own movement', () {
      notifier().setSkeletonReturned(1);

      final movements = container
          .read(saleDraftProvider)
          .toContainerMovements('c-1', null);

      expect(movements, hasLength(1));
      expect(movements.single.containerType, 'ESQUELETO');
      expect(movements.single.deliveredQuantity, 0);
      expect(movements.single.returnedQuantity, 1);
    });

    test('no skeleton movement while both quantities are 0', () {
      notifier().setQuantity(SaleItem(product: siphon, quantity: 0), 2);

      final movements = container
          .read(saleDraftProvider)
          .toContainerMovements('c-1', null);

      expect(movements.map((m) => m.containerType), ['SIFON_2L']);
    });
  });
}
