import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/domain/usecases/register_container_return.usecase.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/inventory/presentation/providers/register_container_return_usecase_provider.dart';
import 'package:app/features/inventory/presentation/widgets/register_container_return_dialog.dart';

class _FakeRegisterContainerReturn implements RegisterContainerReturnUseCase {
  final calls =
      <({String customerId, String? visitId, Map<String, int> returns})>[];

  @override
  Future<Resource<void>> execute({
    required String customerId,
    required Map<String, int> returns,
    String? visitId,
    String? routeId,
  }) async {
    calls.add((customerId: customerId, visitId: visitId, returns: returns));
    return const Resource.success(null);
  }
}

void main() {
  testWidgets(
    'saves the returns of the catalog types and closes with a toast',
    (tester) async {
      final fake = _FakeRegisterContainerReturn();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            registerContainerReturnUseCaseProvider.overrideWithValue(fake),
            containerTypesProvider.overrideWith(
              (_) => Stream.value(const [
                ContainerType(id: 1, code: 'JUG', label: 'Bidón 20L'),
                ContainerType(id: 2, code: 'SIPHON', label: 'Sifón 1.5L'),
              ]),
            ),
            customerContainerBalancesProvider('c-1').overrideWith(
              (_) => Stream.value(const [
                CustomerContainerBalance(
                  customerId: 'c-1',
                  containerType: 'SIPHON',
                  quantity: 1,
                ),
              ]),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [MarilinTokens.light]),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const RegisterContainerReturnDialog(
                      customerId: 'c-1',
                      visitId: 's-1',
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Bidón 20L'), findsOneWidget);
      expect(find.text('Sifón 1.5L'), findsOneWidget);
      await tester.tap(find.byTooltip('Sumar').last);
      await tester.pump();
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(fake.calls.single.customerId, 'c-1');
      expect(fake.calls.single.visitId, 's-1');
      expect(fake.calls.single.returns, {'JUG': 0, 'SIPHON': 1});
      expect(find.byType(RegisterContainerReturnDialog), findsNothing);
      expect(find.text('Retorno de envases registrado'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 4));
    },
  );
}
