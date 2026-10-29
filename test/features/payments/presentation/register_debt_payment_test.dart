import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/usecases/register_payment.usecase.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/payments/presentation/register_debt_payment.dart';

class _FakeRegisterPayment implements RegisterPaymentUseCase {
  _FakeRegisterPayment({this.fail = false});

  final bool fail;
  final recorded = <List<Payment>>[];

  @override
  Future<Resource<void>> execute(List<Payment> payments) async {
    recorded.add(payments);
    return fail
        ? Resource.error(Exception('boom'))
        : const Resource.success(null);
  }
}

final _customer = Customer(
  id: 'c1',
  name: 'Kiosco Norte',
  addresses: const [],
  preferences: const [],
);

Future<void> _pump(WidgetTester tester, _FakeRegisterPayment fake) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [registerPaymentUseCaseProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: ThemeData(extensions: const [MarilinTokens.light]),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => registerDebtPayment(
                context,
                ref,
                customer: _customer,
                debt: 1000,
                visitId: 'v1',
              ),
              child: const Text('Pagar'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Pagar'));
  await tester.pumpAndSettle();
}

Future<void> _payCash(WidgetTester tester) async {
  await tester.tap(find.text('Efectivo'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '400');
  await tester.pump();
  await tester.tap(find.text('Registrar monto ingresado'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('success records the payment and shows the success toast', (
    tester,
  ) async {
    final fake = _FakeRegisterPayment();
    await _pump(tester, fake);
    await _payCash(tester);

    expect(fake.recorded, hasLength(1));
    final payment = fake.recorded.single.single;
    expect(payment.customerId, 'c1');
    expect(payment.amount, 400);
    expect(payment.type, PaymentType.cash);
    expect(payment.visitId, 'v1');
    expect(find.text('Pago registrado con éxito'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('error shows the error toast', (tester) async {
    final fake = _FakeRegisterPayment(fail: true);
    await _pump(tester, fake);
    await _payCash(tester);

    expect(fake.recorded, hasLength(1));
    expect(find.text('No se guardó el pago. Reintentá.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a mixed payment records cash first and the transfer after it', (
    tester,
  ) async {
    final fake = _FakeRegisterPayment();
    await _pump(tester, fake);
    await tester.tap(find.text('Mixto'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '600');
    await tester.enterText(fields.at(1), '400');
    await tester.pump();
    await tester.tap(find.text('Registrar monto ingresado'));
    await tester.pumpAndSettle();

    final payments = fake.recorded.single;
    expect(payments.map((p) => p.type), [
      PaymentType.cash,
      PaymentType.transfer,
    ]);
    expect(payments.map((p) => p.amount), [600, 400]);
    expect(
      payments[1].createdAt,
      payments[0].createdAt.add(const Duration(milliseconds: 10)),
    );
    expect(payments.map((p) => p.visitId), ['v1', 'v1']);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('cancel registers nothing', (tester) async {
    final fake = _FakeRegisterPayment();
    await _pump(tester, fake);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(fake.recorded, isEmpty);
    expect(find.text('Pago registrado con éxito'), findsNothing);
  });
}
