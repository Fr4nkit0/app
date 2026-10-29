import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/providers/clock_provider.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';
import 'package:app/features/visits/presentation/providers/complete_visit_usecase_provider.dart';

void main() {
  test('the provided use case checks reschedule times against the injected '
      'clock', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 19, 8)),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(completeVisitUseCaseProvider)
          .execute(
            stopId: 'stop-1',
            customerId: 'c-1',
            visitType: VisitType.visit,
            nextStatus: StopStatus.absent,
            rescheduleAt: DateTime(2026, 10, 19, 7, 30),
          ),
      throwsA(
        isA<ValidationFailure>().having(
          (e) => e.message,
          'message',
          'Elegí una hora posterior a la actual.',
        ),
      ),
    );
  });
}
