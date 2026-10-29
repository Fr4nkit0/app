import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/providers/clock_provider.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';
import 'package:app/features/visits/domain/reschedule_time.dart';
import 'package:app/features/visits/domain/usecases/complete_visit.usecase.dart';
import 'package:app/features/visits/presentation/providers/complete_visit_usecase_provider.dart';
import 'package:app/features/visits/presentation/providers/visit_session.dart';

class _Call {
  _Call({
    required this.stopId,
    required this.customerId,
    required this.visitType,
    required this.nextStatus,
    required this.outcomeId,
    required this.observations,
    required this.rescheduleAt,
  });

  final String stopId;
  final String customerId;
  final VisitType visitType;
  final StopStatus nextStatus;
  final int? outcomeId;
  final String? observations;
  final DateTime? rescheduleAt;
}

class _FakeCompleteVisit implements CompleteVisitUseCase {
  final calls = <_Call>[];
  Object? error;
  Completer<void>? gate;

  @override
  Future<void> execute({
    required String stopId,
    required String customerId,
    required VisitType visitType,
    required StopStatus nextStatus,
    int? outcomeId,
    String? observations,
    DateTime? rescheduleAt,
  }) async {
    calls.add(
      _Call(
        stopId: stopId,
        customerId: customerId,
        visitType: visitType,
        nextStatus: nextStatus,
        outcomeId: outcomeId,
        observations: observations,
        rescheduleAt: rescheduleAt,
      ),
    );
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
  }
}

const _absent = VisitOutcome(
  id: 1,
  code: 'absent',
  name: 'Ausente',
  triggersReschedule: false,
);
const _reschedule = VisitOutcome(
  id: 2,
  code: 'reschedule',
  name: 'Reprogramar',
  triggersReschedule: true,
);
const _refused = VisitOutcome(
  id: 3,
  code: 'refused',
  name: 'No quiso',
  triggersReschedule: false,
);

final _stop = RouteStop(
  id: 's-1',
  customer: Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  ),
  status: StopStatus.pending,
  scheduledAt: DateTime(2026, 10, 28, 9),
);

final _sale = Sale(
  id: 'sale-1',
  customer: _stop.customer,
  items: const [
    SaleItem(
      product: Product(id: 'p-1', name: 'Soda', unitLabel: 'u', price: 100),
      quantity: 1,
    ),
  ],
  total: 100,
  paymentMethod: PaymentMethod.cash,
  date: DateTime(2026, 10, 28),
  visitId: 's-1',
);

final _payment = Payment(
  id: 'pay-1',
  customerId: 'c-1',
  amount: 100,
  type: PaymentType.cash,
  createdAt: DateTime(2026, 10, 28, 10),
  visitId: 's-1',
);

final _return = ContainerMovement(
  id: 'm-1',
  customerId: 'c-1',
  containerType: 'BOTTLE',
  deliveredQuantity: 0,
  returnedQuantity: 2,
  createdAt: DateTime(2026, 10, 28, 10),
  visitId: 's-1',
);

/// The visit of stop s-1 with its activity streams and a fixed clock.
class _Harness {
  _Harness({
    List<Sale> sales = const [],
    List<ContainerMovement> movements = const [],
  }) {
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        completeVisitUseCaseProvider.overrideWithValue(useCase),
        routeStopByIdProvider('s-1').overrideWithValue(_stop),
        stopSalesProvider('s-1').overrideWith((_) => this.sales.stream),
        visitPaymentsProvider('s-1').overrideWith((_) => payments.stream),
        visitMovementsProvider('s-1').overrideWith((_) async => movements),
      ],
    );
    container.listen(visitSessionProvider('s-1'), (_, _) {});
    this.sales.add(sales);
    payments.add(const []);
  }

  late final ProviderContainer container;
  final useCase = _FakeCompleteVisit();
  final sales = StreamController<List<Sale>>();
  final payments = StreamController<List<Payment>>();
  DateTime now = DateTime(2026, 10, 28, 10);

  VisitSessionState get state => container.read(visitSessionProvider('s-1'));
  VisitSession get session =>
      container.read(visitSessionProvider('s-1').notifier);

  /// Lets the activity streams and futures reach the session.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> dispose() async {
    container.dispose();
    await sales.close();
    await payments.close();
  }
}

Future<_Harness> _start({
  List<Sale> sales = const [],
  List<ContainerMovement> movements = const [],
}) async {
  final harness = _Harness(sales: sales, movements: movements);
  addTearDown(harness.dispose);
  await harness.settle();
  return harness;
}

void main() {
  group('outcome enablement', () {
    test('without returns or payments every outcome is enabled', () async {
      final h = await _start();

      expect(h.state.isOutcomeEnabled(_absent), isTrue);
      expect(h.state.isOutcomeEnabled(_reschedule), isTrue);
      expect(h.state.isOutcomeEnabled(_refused), isTrue);
    });

    test('returns disable absent and reschedule but not a refusal', () async {
      final h = await _start(movements: [_return]);

      expect(h.state.hasReturns, isTrue);
      expect(h.state.isOutcomeEnabled(_absent), isFalse);
      expect(h.state.isOutcomeEnabled(_reschedule), isFalse);
      expect(h.state.isOutcomeEnabled(_refused), isTrue);
    });

    test('payments disable absent and reschedule', () async {
      final h = await _start();
      h.payments.add([_payment]);
      await h.settle();

      expect(h.state.hasPayments, isTrue);
      expect(h.state.isOutcomeEnabled(_absent), isFalse);
      expect(h.state.isOutcomeEnabled(_reschedule), isFalse);
    });

    test('a disabled outcome cannot be selected', () async {
      final h = await _start(movements: [_return]);

      h.session.selectOutcome(_reschedule);

      expect(h.state.selectedOutcome, isNull);
    });
  });

  group('reschedule cleared by activity', () {
    test('a selected reschedule is cleared when a payment appears', () async {
      final h = await _start();
      h.session.selectOutcome(_reschedule);
      expect(h.state.isRescheduleSelected, isTrue);

      h.payments.add([_payment]);
      await h.settle();

      expect(h.state.selectedOutcome, isNull);
      expect(h.state.isRescheduleSelected, isFalse);
    });

    test('an outcome that does not reschedule stays selected', () async {
      final h = await _start();
      h.session.selectOutcome(_absent);

      h.payments.add([_payment]);
      await h.settle();

      expect(h.state.selectedOutcome, _absent);
    });
  });

  group('canClose and nextStatus', () {
    test('a visit without sales needs an outcome to close', () async {
      final h = await _start();
      expect(h.state.canClose, isFalse);

      h.session.selectOutcome(_absent);

      expect(h.state.canClose, isTrue);
    });

    test('a visit with sales can close without an outcome', () async {
      final h = await _start(sales: [_sale]);

      expect(h.state.hasSales, isTrue);
      expect(h.state.canClose, isTrue);
      expect(h.state.nextStatus, StopStatus.done);
    });

    test('a reschedule closes the stop as absent, any other outcome as '
        'done', () async {
      final h = await _start();

      h.session.selectOutcome(_reschedule);
      expect(h.state.nextStatus, StopStatus.absent);

      h.session.selectOutcome(_absent);
      expect(h.state.nextStatus, StopStatus.done);
    });

    test(
      'in sale mode without sales the primary action starts a sale',
      () async {
        final h = await _start();
        expect(h.state.startsSale, isFalse);

        h.session.selectSaleMode();
        expect(h.state.startsSale, isTrue);
        expect(h.state.visitType, VisitType.sale);

        h.session.selectVisitMode();
        expect(h.state.startsSale, isFalse);
        expect(h.state.visitType, VisitType.visit);
      },
    );
  });

  group('reschedule time', () {
    test('the picker starts one hour after now', () async {
      final h = await _start();

      expect(
        h.session.initialRescheduleTime(),
        const TimeOfDay(hour: 11, minute: 0),
      );
    });

    test('a time not later than now is rejected as notLater', () async {
      final h = await _start();
      h.session.selectOutcome(_reschedule);

      h.session.setRescheduleTime(const TimeOfDay(hour: 9, minute: 30));

      expect(h.state.rescheduleTime, const TimeOfDay(hour: 9, minute: 30));
      expect(h.state.rescheduleError, RescheduleTimeError.notLater);
    });

    test('a later time today clears the error', () async {
      final h = await _start();
      h.session.selectOutcome(_reschedule);
      h.session.setRescheduleTime(const TimeOfDay(hour: 9, minute: 30));

      h.session.setRescheduleTime(const TimeOfDay(hour: 11, minute: 15));

      expect(h.state.rescheduleError, isNull);
      expect(
        h.session.initialRescheduleTime(),
        const TimeOfDay(hour: 11, minute: 15),
      );
    });
  });
}
