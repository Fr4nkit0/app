import 'dart:async';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/route/data/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/domain/models/visit_type.dart';

class MockRouteRepository implements RouteRepository {
  MockRouteRepository() {
    _stops = _buildInitialStops();
    _controller = StreamController<List<RouteStop>>.broadcast();
  }

  late List<RouteStop> _stops;
  late StreamController<List<RouteStop>> _controller;

  @override
  Stream<List<RouteStop>> watchDayStops() async* {
    yield List.of(_stops);
    yield* _controller.stream;
  }

  @override
  Future<void> markStop(String id, StopStatus status) async {
    final idx = _stops.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      _stops[idx] = _stops[idx].copyWith(status: status);
      _sortStops(_stops);
      _controller.add(List.of(_stops));
    }
  }

  static final _customer1 = Customer(
    id: 'mock-1',
    name: 'José García',
    addresses: [
      CustomerAddress(id: 'addr-1', street: 'Av. San Martín 1234', isPrimary: true),
    ],
    preferences: const [],
    debtAmount: 1200,
    productLabels: const ['3 Bidones', '2 Sifones'],
  );

  static final _customer2 = Customer(
    id: 'mock-2',
    name: 'Laura Gómez',
    addresses: [
      CustomerAddress(id: 'addr-2', street: 'Belgrano 456', isPrimary: true),
    ],
    preferences: const [],
    productLabels: const ['1 Bidón'],
  );

  static final _customer3 = Customer(
    id: 'mock-3',
    name: "Despensa 'El Sol'",
    addresses: [
      CustomerAddress(id: 'addr-3', street: 'Mitre 789', isPrimary: true),
    ],
    preferences: const [],
    debtAmount: 6500,
    productLabels: const ['10 Bidones'],
  );

  static final _customer4 = Customer(
    id: 'mock-4',
    name: 'Kiosco Don Juan',
    addresses: [
      CustomerAddress(id: 'addr-4', street: 'Zuviría 101', isPrimary: true),
    ],
    preferences: const [],
    debtAmount: 0.0,
    productLabels: const ['5 Bidones'],
  );

  static List<RouteStop> _buildInitialStops() {
    final now = DateTime.now();
    final List<RouteStop> stops = [];

    // Add initial static stops
    stops.addAll([
      RouteStop(
        id: 'stop-1',
        customer: _customer1,
        visitType: VisitType.sale,
        status: StopStatus.pending,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      ),
      RouteStop(
        id: 'stop-2',
        customer: _customer2,
        visitType: VisitType.visit,
        status: StopStatus.pending,
        scheduledAt: DateTime(now.year, now.month, now.day, 10, 30),
      ),
      RouteStop(
        id: 'stop-3',
        customer: _customer3,
        visitType: VisitType.sale,
        status: StopStatus.pending,
        scheduledAt: DateTime(now.year, now.month, now.day, 12, 0),
      ),
      RouteStop(
        id: 'stop-4',
        customer: _customer4,
        visitType: VisitType.sale,
        status: StopStatus.done,
        scheduledAt: DateTime(now.year, now.month, now.day, 14, 0),
      ),
    ]);

    // Programmatically generate 46 more stops to reach exactly 50
    for (int i = 5; i <= 50; i++) {
      final hour = 8 + (i ~/ 3);
      final minute = (i % 3) * 20;
      final isDone = i % 7 == 0;
      final isAbsent = i % 13 == 0;

      final customer = Customer(
        id: 'mock-$i',
        name: 'Cliente N° $i',
        addresses: [
          CustomerAddress(id: 'addr-$i', street: 'Calle Falsa ${100 + i}', isPrimary: true),
        ],
        preferences: const [],
        debtAmount: i % 5 == 0 ? (i * 150).toDouble() : 0.0,
        productLabels: ['${1 + (i % 3)} Bidones'],
      );

      stops.add(
        RouteStop(
          id: 'stop-$i',
          customer: customer,
          visitType: i % 2 == 0 ? VisitType.sale : VisitType.visit,
          status: isDone
              ? StopStatus.done
              : isAbsent
                  ? StopStatus.absent
                  : StopStatus.pending,
          scheduledAt: DateTime(now.year, now.month, now.day, hour, minute),
        ),
      );
    }

    _sortStops(stops);
    return stops;
  }

  static void _sortStops(List<RouteStop> list) {
    list.sort((a, b) {
      final aPending = a.status == StopStatus.pending;
      final bPending = b.status == StopStatus.pending;
      if (aPending != bPending) {
        return aPending ? -1 : 1;
      }
      return a.scheduledAt.compareTo(b.scheduledAt);
    });
  }
}
