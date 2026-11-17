import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/balance_corrections/domain/models/balance_correction.dart';
import 'package:app/features/balance_corrections/domain/usecases/correct_balance.usecase.dart';
import 'package:app/features/balance_corrections/presentation/providers/correct_balance_usecase_provider.dart';
import 'package:app/features/balance_corrections/presentation/widgets/balance_correction_sheet.dart';
import 'package:app/features/customers/presentation/screens/customer_profile_screen.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// Lets the in-memory database answer; its queries run outside fake time.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('cust-1'),
            name: 'Sanatorio',
            serverId: const drift.Value(10),
          ),
        );
    await db
        .into(db.customerBalanceTable)
        .insert(
          CustomerBalanceTableCompanion.insert(
            customerId: 'cust-1',
            currentBalance: const drift.Value(1500),
          ),
        );
    await db
        .into(db.containerTypeTable)
        .insert(
          ContainerTypeTableCompanion.insert(
            id: const drift.Value(1),
            code: 'B20',
            description: const drift.Value('Bidón 20L'),
          ),
        );
    await db
        .into(db.customerContainerBalanceTable)
        .insert(
          CustomerContainerBalanceTableCompanion.insert(
            customerId: 'cust-1',
            containerType: 'B20',
            quantity: const drift.Value(3),
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> pumpProfile(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...overrides],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CustomerProfileScreen(customerId: 'cust-1'),
        ),
      ),
    );
    await settle(tester);
  }

  // Drift schedules a zero-duration timer when a watched query is cancelled.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  Future<List<PendingEntity>> queued() async => [
    for (final c in await DriftPendingChangeRepository(db).getPending())
      c.entity,
  ];

  final correct = find.byTooltip('Corregir saldo');
  final count = find.byKey(BalanceCorrectionSheet.countFieldKey);
  final reason = find.byKey(BalanceCorrectionSheet.reasonFieldKey);
  final confirm = find.widgetWithText(FilledButton, 'Guardar corrección');

  Future<void> fillAndConfirm(
    WidgetTester tester,
    String counted,
    String why,
  ) async {
    await tester.enterText(count, counted);
    await tester.enterText(reason, why);
    await tester.pump();
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await settle(tester);
  }

  testWidgets('the driver corrects the debt from the debt card: the shown '
      'balance moves and the correction is queued', (tester) async {
    await pumpProfile(tester);
    expect(find.text('Debe \$1.500'), findsOneWidget);
    expect(correct, findsNWidgets(2));

    await tester.tap(correct.first);
    await settle(tester);
    expect(find.text('Corregir saldo'), findsOneWidget);

    await fillAndConfirm(tester, '500', 'Pagó en efectivo a la oficina');

    expect(find.byType(BalanceCorrectionSheet), findsNothing);
    expect(
      find.text('Saldo corregido. Queda pendiente de revisión.'),
      findsOneWidget,
    );
    expect(find.text('Debe \$500'), findsOneWidget);
    expect(find.text('Debe \$1.500'), findsNothing);
    expect(
      await tester.runAsync(queued),
      contains(PendingEntity.balanceCorrection),
    );
    final row = await tester.runAsync(
      () => db.select(db.balanceCorrectionTable).getSingle(),
    );
    expect(row!.target, 'debt');
    expect(row.counted, 500);
    expect(row.seenBalance, 1500);
    expect(row.reason, 'Pagó en efectivo a la oficina');
    await unmount(tester);
  });

  testWidgets('the custody card opens on its containers and corrects them', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(correct.last);
    await settle(tester);
    await fillAndConfirm(tester, '5', 'Conté 5 bidones');

    final row = await tester.runAsync(
      () => db.select(db.balanceCorrectionTable).getSingle(),
    );
    expect(row!.target, 'containers');
    expect(row.containerType, 'B20');
    expect(row.counted, 5);
    expect(row.seenBalance, 3);
    expect(find.text('5'), findsOneWidget);
    await unmount(tester);
  });

  for (final (error, shown) in [
    (
      const ValidationFailure(CorrectBalanceUseCase.reasonTooLong),
      CorrectBalanceUseCase.reasonTooLong,
    ),
    (StateError('disk full'), 'No se guardó la corrección. Reintentá.'),
  ]) {
    testWidgets('a failed correction ($shown) keeps the sheet open and '
        'changes nothing', (tester) async {
      await pumpProfile(
        tester,
        overrides: [
          correctBalanceUseCaseProvider.overrideWithValue(
            _FailingCorrectBalance(error),
          ),
        ],
      );

      await tester.tap(correct.first);
      await settle(tester);
      await fillAndConfirm(tester, '500', 'Pagó en la oficina');

      expect(find.byType(BalanceCorrectionSheet), findsOneWidget);
      expect(find.text(shown), findsOneWidget);
      expect(find.text('Debe \$1.500'), findsWidgets);
      expect(await tester.runAsync(queued), isEmpty);
      await unmount(tester);
    });
  }

  testWidgets('tapping the cards still pays the debt and returns '
      'containers', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Debe \$1.500'));
    await settle(tester);
    expect(find.text('Forma de pago'), findsOneWidget);
    Navigator.of(tester.element(find.text('Forma de pago'))).pop();
    await settle(tester);

    await tester.tap(find.text('Comodatos activos'));
    await settle(tester);
    expect(find.byType(Dialog), findsOneWidget);
    await unmount(tester);
  });
}

/// Fails every correction with [error], as a rejected write would.
class _FailingCorrectBalance implements CorrectBalanceUseCase {
  _FailingCorrectBalance(this.error);

  final Object error;

  @override
  Future<BalanceCorrection> execute({
    required String customerId,
    required BalanceTarget target,
    required num counted,
    required String reason,
    String? containerType,
    String? visitId,
  }) => Future.error(error);
}
