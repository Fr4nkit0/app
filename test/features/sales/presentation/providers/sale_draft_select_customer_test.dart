import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';

Customer _customer(String id) =>
    Customer(id: id, name: id, addresses: const [], preferences: const []);

void main() {
  // Priced with an agreement of customer A.
  const agreed = Product(
    id: 'p1',
    name: 'Soda',
    unitLabel: 'u',
    price: 1300,
    containerType: 'SIFON_1.2L',
    agreementId: 19,
  );

  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  SaleDraft notifier() => container.read(saleDraftProvider.notifier);

  test('choosing another customer drops the lines priced for the previous '
      'one', () {
    notifier().selectCustomer(_customer('A'));
    notifier().setQuantity(SaleItem(product: agreed, quantity: 0), 6);
    notifier().setSkeletonDelivered(1);

    notifier().selectCustomer(_customer('B'));

    final draft = container.read(saleDraftProvider);
    expect(draft.customer?.id, 'B');
    expect(draft.items, isEmpty);
    expect(draft.returnedContainers, isEmpty);
    expect(draft.skeletonDelivered, 0);
  });

  test('choosing the same customer again keeps the lines', () {
    notifier().selectCustomer(_customer('A'));
    notifier().setQuantity(SaleItem(product: agreed, quantity: 0), 6);

    notifier().selectCustomer(_customer('A'), visitId: 'v-1');

    final draft = container.read(saleDraftProvider);
    expect(draft.items.single.quantity, 6);
    expect(draft.items.single.product.agreementId, 19);
    expect(draft.visitId, 'v-1');
  });
}
