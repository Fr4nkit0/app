import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_form_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';
import 'package:app/features/customers/presentation/screens/create_customer_screens.dart';

import '../providers/customer_form_provider_test.dart' show FakeCustomerRepository;

void main() {
  testWidgets('saving a new customer closes the form and returns that customer', (tester) async {
    Customer? returned;
    late WidgetRef hostRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [customerRepositoryProvider.overrideWithValue(FakeCustomerRepository())],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              hostRef = ref;
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    returned = await Navigator.of(context).push<Customer>(
                      MaterialPageRoute(builder: (_) => const CreateCustomerScreen()),
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final form = hostRef.read(customerFormProvider.notifier)
      ..updateName('Juan Carlos')
      ..nextStep()
      ..updateStreet('Himalayas 10')
      ..updateNeighborhood('Centro')
      ..nextStep();
    await tester.pump();
    await form.submit();
    await tester.pumpAndSettle();

    expect(find.byType(CreateCustomerScreen), findsNothing);
    expect(returned?.name, 'Juan Carlos');
  });
}
