import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/errors/domain_failure.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/payments/domain/models/payment_split.dart';
import 'package:app/features/payments/domain/usecases/register_debt_payment.usecase.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/payments/presentation/register_debt_payment.dart';

typedef _Call = ({String customerId, PaymentSplit split, String? visitId});

class _FakeRegisterDebtPayment implements RegisterDebtPaymentUseCase {
  _FakeRegisterDebtPayment({this.failure});

  final Object? failure;
  final recorded = <_Call>[];

  @override
  Future<void> execute({
    required String customerId,
    required PaymentSplit split,
    String? visitId,
  }) async {
    recorded.add((customerId: customerId, split: split, visitId: visitId));
    if (failure case final failure?) throw failure;
  }
}

final _customer = Customer(
  id: 'c1',
  name: 'Kiosco Norte',
  addresses: const [],
  preferences: const [],
);

Future<void> _pump(WidgetTester tester, _FakeRegisterDebtPayment fake) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [registerDebtPaymentUseCaseProvider.overrideWithValue(fake)],
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
    final fake = _FakeRegisterDebtPayment();
    await _pump(tester, fake);
    await _payCash(tester);

    final call = fake.recorded.single;
    expect(call.customerId, 'c1');
    expect(call.split, const PaymentSplit(cash: 400));
    expect(call.visitId, 'v1');
    expect(find.text('Pago registrado con éxito'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('error shows the error toast', (tester) async {
    final fake = _FakeRegisterDebtPayment(
      failure: StorageFailure(Exception('boom')),
    );
    await _pump(tester, fake);
    await _payCash(tester);

    expect(fake.recorded, hasLength(1));
    expect(find.text('No se guardó el pago. Reintentá.'), findsOneWidget);
    expect(find.text('Pago registrado con éxito'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a rejected payment shows the rule message', (tester) async {
    final fake = _FakeRegisterDebtPayment(
      failure: const ValidationFailure('Ingresá un monto mayor a 0.'),
    );
    await _pump(tester, fake);
    await _payCash(tester);

    expect(find.text('Ingresá un monto mayor a 0.'), findsOneWidget);
    expect(find.text('No se guardó el pago. Reintentá.'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a mixed payment passes both parts of the split', (tester) async {
    final fake = _FakeRegisterDebtPayment();
    await _pump(tester, fake);
    await tester.tap(find.text('Mixto'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '600');
    await tester.enterText(fields.at(1), '400');
    await tester.pump();
    await tester.tap(find.text('Registrar monto ingresado'));
    await tester.pumpAndSettle();

    final call = fake.recorded.single;
    expect(call.split, const PaymentSplit(cash: 600, transfer: 400));
    expect(call.visitId, 'v1');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('cancel registers nothing', (tester) async {
    final fake = _FakeRegisterDebtPayment();
    await _pump(tester, fake);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(fake.recorded, isEmpty);
    expect(find.text('Pago registrado con éxito'), findsNothing);
  });
}
