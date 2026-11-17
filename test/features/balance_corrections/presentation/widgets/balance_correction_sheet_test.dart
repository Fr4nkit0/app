import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/balance_corrections/domain/models/balance_correction.dart';
import 'package:app/features/balance_corrections/presentation/widgets/balance_correction_sheet.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';

typedef Emitted = ({
  BalanceTarget target,
  String? containerType,
  num counted,
  String reason,
});

void main() {
  const types = [
    ContainerType(id: 1, code: 'B20', label: 'Bidón 20L'),
    ContainerType(id: 2, code: 'SIF', label: 'Sifón'),
  ];

  final emitted = <Emitted>[];
  setUp(emitted.clear);

  Future<void> pumpSheet(
    WidgetTester tester, {
    double debt = 1500,
    Map<String, int> custody = const {'B20': 3},
    BalanceTarget initialTarget = BalanceTarget.debt,
    String? initialContainerType,
  }) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: BalanceCorrectionSheet(
            debt: debt,
            containerTypes: types,
            custody: custody,
            initialTarget: initialTarget,
            initialContainerType: initialContainerType,
            onConfirm: (target, containerType, counted, reason) async {
              emitted.add((
                target: target,
                containerType: containerType,
                counted: counted,
                reason: reason,
              ));
            },
          ),
        ),
      ),
    );
  }

  final count = find.byKey(BalanceCorrectionSheet.countFieldKey);
  final reason = find.byKey(BalanceCorrectionSheet.reasonFieldKey);
  final confirm = find.widgetWithText(FilledButton, 'Guardar corrección');

  bool confirmEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(confirm).onPressed != null;

  Future<void> tapConfirm(WidgetTester tester) async {
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pump();
  }

  testWidgets('lists the debt and every container type with its current '
      'value, and says the correction applies now', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Deuda'), findsOneWidget);
    expect(find.text('Debe \$1.500'), findsOneWidget);
    expect(find.text('Bidón 20L'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Sifón'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(
      find.text('Se aplica ahora y la oficina la revisa.'),
      findsOneWidget,
    );
  });

  testWidgets('a container type the catalog lacks is not offered: the '
      'server could never take its correction', (tester) async {
    await pumpSheet(tester, custody: const {'B20': 3, 'OLD': 2});

    expect(find.text('OLD'), findsNothing);
    expect(find.text('2'), findsNothing);
  });

  testWidgets('confirm stays disabled until the count parses and the '
      'trimmed reason has 3 characters', (tester) async {
    await pumpSheet(tester);
    expect(confirmEnabled(tester), isFalse);

    await tester.enterText(count, '1000');
    await tester.pump();
    expect(confirmEnabled(tester), isFalse);

    await tester.enterText(reason, '  ab  ');
    await tester.pump();
    expect(confirmEnabled(tester), isFalse);

    await tester.enterText(reason, 'abc');
    await tester.pump();
    expect(confirmEnabled(tester), isTrue);

    await tester.enterText(count, '');
    await tester.pump();
    expect(confirmEnabled(tester), isFalse);
  });

  testWidgets('the debt preview reads "Pasa de <actual> a <nuevo>"', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.textContaining('Pasa de'), findsNothing);
    await tester.enterText(count, '1000');
    await tester.pump();
    expect(find.text('Pasa de Debe \$1.500 a Debe \$1.000'), findsOneWidget);

    await tester.enterText(count, '0');
    await tester.pump();
    expect(find.text('Pasa de Debe \$1.500 a Al día'), findsOneWidget);
  });

  testWidgets('choosing "Saldo a favor" emits a negative counted debt and '
      'never shows a negative amount', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(count, '200');
    await tester.tap(find.text('Saldo a favor'));
    await tester.pump();
    expect(
      find.text('Pasa de Debe \$1.500 a Saldo a favor: \$200'),
      findsOneWidget,
    );
    expect(find.textContaining('-\$'), findsNothing);

    await tester.enterText(reason, 'Pagó por adelantado');
    await tester.pump();
    await tapConfirm(tester);

    expect(emitted, [
      (
        target: BalanceTarget.debt,
        containerType: null,
        counted: -200,
        reason: 'Pagó por adelantado',
      ),
    ]);
  });

  testWidgets('a debt in credit opens on "Saldo a favor"', (tester) async {
    await pumpSheet(tester, debt: -300);

    expect(find.text('Saldo a favor: \$300'), findsOneWidget);
    await tester.enterText(count, '100');
    await tester.pump();
    expect(
      find.text('Pasa de Saldo a favor: \$300 a Saldo a favor: \$100'),
      findsOneWidget,
    );
  });

  testWidgets('the reason is emitted trimmed', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(count, '1200,50');
    await tester.enterText(reason, '   Se anotó mal un cobro   ');
    await tester.pump();
    await tapConfirm(tester);

    expect(emitted.single.reason, 'Se anotó mal un cobro');
    expect(emitted.single.counted, 1200.5);
  });

  testWidgets('containers: decimals are not accepted', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.text('Bidón 20L'));
    await tester.pump();

    await tester.enterText(reason, 'Conté de nuevo');
    for (final typed in ['2.5', '2,5']) {
      await tester.enterText(count, typed);
      await tester.pump();
      expect(
        find.text('Ingresá un número entero, sin decimales.'),
        findsOneWidget,
      );
      expect(find.textContaining('Pasa de'), findsNothing);
      expect(confirmEnabled(tester), isFalse);
    }
    await tapConfirm(tester);
    expect(emitted, isEmpty);
  });

  testWidgets('containers: previews and emits the whole count of the chosen '
      'type', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.text('Bidón 20L'));
    await tester.pump();

    await tester.enterText(count, '5');
    await tester.enterText(reason, 'Conté 5 en el depósito');
    await tester.pump();
    expect(find.text('Pasa de 3 a 5'), findsOneWidget);
    expect(find.text('Debe'), findsNothing);
    await tapConfirm(tester);

    expect(emitted, [
      (
        target: BalanceTarget.containers,
        containerType: 'B20',
        counted: 5,
        reason: 'Conté 5 en el depósito',
      ),
    ]);
    expect(emitted.single.counted, isA<int>());
  });

  testWidgets('opens on the initial container type', (tester) async {
    await pumpSheet(
      tester,
      initialTarget: BalanceTarget.containers,
      initialContainerType: 'SIF',
    );

    await tester.enterText(count, '4');
    await tester.enterText(reason, 'Tenía 4 sifones');
    await tester.pump();
    expect(find.text('Pasa de 0 a 4'), findsOneWidget);
    await tapConfirm(tester);

    expect(emitted.single.target, BalanceTarget.containers);
    expect(emitted.single.containerType, 'SIF');
  });
}
