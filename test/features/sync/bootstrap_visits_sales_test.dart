import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/route/data/repositories/drift_route_repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/pull/pull_applier.dart' show dateOnly;
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

Map<String, dynamic> _visit({
  int id = 501,
  String? clientUuid = 'visit-uuid-501',
  int stopId = 72,
  int customerId = 12,
  int? outcomeId,
  String? notes,
  required String date,
}) => {
  'id': id,
  'client_uuid': clientUuid,
  'route_stop_id': stopId,
  'customer_id': customerId,
  'driver_id': 1,
  'outcome_id': outcomeId,
  'arrived_at': '${date}T13:05:00.000000Z',
  'latitude': null,
  'longitude': null,
  'altitude': null,
  'status': 'CLOSED',
  'notes': notes,
  'needs_review': false,
  'review_reason': null,
};

Map<String, dynamic> _sale({
  int id = 601,
  String? clientUuid = 'sale-uuid-601',
  String status = 'confirmed',
  required String date,
}) => {
  'id': id,
  'client_uuid': clientUuid,
  'customer_id': 12,
  'visit_id': 501,
  'date': date,
  'total': '2700.00',
  'status': status,
  'is_credit_sale': true,
  'notes': null,
  'stock_route_id': 7,
  'needs_review': false,
  'review_reason': null,
  'details': [
    {
      'id': 6001,
      'sale_id': id,
      'product_id': 21,
      'customer_agreement_id': 1200,
      'quantity': 2,
      'unit_price': '1350.00',
    },
  ],
};

Map<String, dynamic> _payload(
  String date, {
  List<Map<String, dynamic>> visits = const [],
  List<Map<String, dynamic>> sales = const [],
}) => {
  'data': {
    'route': {'id': 7, 'date': date, 'status': 'IN_PROGRESS'},
    'stops': [
      {'id': 71, 'route_id': 7, 'customer_id': 11, 'status': 'FINISHED'},
      {'id': 72, 'route_id': 7, 'customer_id': 12, 'status': 'FINISHED'},
    ],
    'truck_inventory': [
      {'id': 900, 'route_id': 7, 'product_id': 21, 'current_quantity': '20.00'},
    ],
    'customers': [
      {'id': 11, 'client_uuid': 'cust-uuid-11', 'name': 'Ana'},
      {
        'id': 12,
        'client_uuid': 'cust-uuid-12',
        'name': 'Beto',
        'agreements': [
          {'id': 1200, 'product_id': 21, 'unit_price': '1350.00', 'valid_from': '2026-10-01'},
        ],
        'balance': {'current_balance': '2700.00'},
      },
    ],
    'products': [
      {'id': 21, 'name': 'Water 20L', 'requires_container': true},
    ],
    'visit_outcomes': [
      {'id': 4, 'code': 'absent', 'name': 'Ausente', 'triggers_reschedule': false},
    ],
    'visits': visits,
    'sales': sales,
    'server_time': '${date}T12:00:00+00:00',
  },
  'message': null,
};

void main() {
  const date = '2026-10-19';
  late AppDatabase db;
  late Map<String, dynamic> response;

  SyncService serviceFor(DateTime Function() today) => SyncService(
    Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json(200, response),
      ),
    db,
    today: today,
  );

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('stores today\'s visits and sales linked by server ids, queues nothing '
      'and moves no balance or stock', () async {
    response = _payload(
      date,
      visits: [
        _visit(date: date),
        _visit(id: 502, clientUuid: null, stopId: 71, customerId: 11, outcomeId: 4, notes: 'Closed door', date: date),
      ],
      sales: [
        _sale(date: date),
        _sale(id: 602, clientUuid: 'sale-uuid-602', status: 'cancelled', date: date),
      ],
    );

    await serviceFor(() => DateTime(2026, 10, 19)).bootstrap();

    final stops = {
      for (final s in await db.select(db.routeStopTable).get()) s.serverId: s,
    };
    final visits = {
      for (final v in await db.select(db.visitTable).get()) v.serverId: v,
    };
    expect(visits.keys, unorderedEquals([501, 502]));
    expect(visits[501]!.visitId, 'visit-uuid-501');
    expect(visits[501]!.routeStopId, stops[72]!.routeStopId);
    expect(visits[501]!.customerId, 'cust-uuid-12');
    expect(visits[501]!.outcomeId, isNull);
    expect(visits[501]!.arrived_at, DateTime.utc(2026, 10, 19, 13, 5).toLocal());
    expect(visits[502]!.routeStopId, stops[71]!.routeStopId);
    expect(visits[502]!.outcomeId, 4);
    expect(visits[502]!.observations, 'Closed door');

    // A cancelled sale is not stored: sales have no status column yet.
    final sale = await db.select(db.saleTable).getSingle();
    expect(sale.saleId, 'sale-uuid-601');
    expect(sale.serverId, 601);
    expect(sale.customerId, 'cust-uuid-12');
    expect(sale.totalAmount, 2700);
    expect(sale.paymentMethod, PaymentMethod.credit.name);
    // Sales of a visit carry its stop's id.
    expect(sale.visitId, stops[72]!.routeStopId);
    final line = await db.select(db.saleItemTable).getSingle();
    final water = await db.select(db.productTable).getSingle();
    expect(line.saleId, sale.saleId);
    expect(line.serverId, 6001);
    expect(line.productId, water.productId);
    expect(line.quantity, 2);
    expect(line.unitPrice, 1350);
    expect(line.subtotal, 2700);
    expect(line.agreementServerId, 1200);
    final entry = await db.select(db.customerAccountEntryTable).getSingle();
    expect(entry.saleId, sale.saleId);
    expect(entry.amount, 2700);

    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    final balance = await (db.select(db.customerBalanceTable)
          ..where((t) => t.customerId.equals('cust-uuid-12')))
        .getSingle();
    expect(balance.currentBalance, 2700);
    expect(water.stock, 20);
  });

  test('links a visit and a sale already on the device, keeping unsent local '
      'values and never duplicating', () async {
    response = _payload(date);
    final service = serviceFor(() => DateTime(2026, 10, 19));
    await service.bootstrap();
    final stop = await (db.select(db.routeStopTable)
          ..where((t) => t.serverId.equals(72)))
        .getSingle();
    final water = await db.select(db.productTable).getSingle();
    await db.into(db.visitTable).insert(
          VisitTableCompanion.insert(
            visitId: const Value('visit-uuid-501'),
            routeStopId: stop.routeStopId,
            customerId: 'cust-uuid-12',
            visitType: 'visit',
            arrived_at: DateTime(2026, 10, 19, 10),
            observations: const Value('Local note'),
          ),
        );
    await db.into(db.saleTable).insert(
          SaleTableCompanion.insert(
            saleId: const Value('sale-uuid-601'),
            customerId: 'cust-uuid-12',
            totalAmount: 2500,
            paymentMethod: PaymentMethod.cash.name,
            quantity: 0,
            shipping_amount: 0,
            visitId: Value(stop.routeStopId),
          ),
        );
    await db.into(db.saleItemTable).insert(
          SaleItemTableCompanion.insert(
            saleId: 'sale-uuid-601',
            productId: water.productId,
            quantity: 2,
            unitPrice: 1250,
            subtotal: 2500,
          ),
        );
    final queue = DriftPendingChangeRepository(db);
    await queue.enqueue(
      entity: PendingEntity.visit,
      entityId: 'visit-uuid-501',
      action: PendingAction.insert,
    );
    await queue.enqueue(
      entity: PendingEntity.sale,
      entityId: 'sale-uuid-601',
      action: PendingAction.insert,
    );

    response = _payload(
      date,
      visits: [_visit(notes: 'Server note', date: date)],
      sales: [_sale(date: date)],
    );
    await service.bootstrap();
    // Matched by server id the second time.
    response = _payload(
      date,
      visits: [_visit(clientUuid: null, notes: 'Server note', date: date)],
      sales: [_sale(clientUuid: null, date: date)],
    );
    await service.bootstrap();

    final visit = await db.select(db.visitTable).getSingle();
    expect(visit.visitId, 'visit-uuid-501');
    expect(visit.serverId, 501);
    expect(visit.observations, 'Local note');
    expect(visit.arrived_at, DateTime(2026, 10, 19, 10));
    final sale = await db.select(db.saleTable).getSingle();
    expect(sale.saleId, 'sale-uuid-601');
    expect(sale.serverId, 601);
    expect(sale.totalAmount, 2500);
    expect(sale.paymentMethod, PaymentMethod.cash.name);
    final line = await db.select(db.saleItemTable).getSingle();
    expect(line.unitPrice, 1250);
    expect(
      (await queue.getPending()).map((c) => c.entityId),
      ['visit-uuid-501', 'sale-uuid-601'],
    );
  });

  test('a closed stop shows its bootstrapped outcome and sale amount', () async {
    final now = DateTime.now();
    final today = dateOnly(now);
    response = _payload(
      today,
      visits: [
        _visit(date: today),
        _visit(id: 502, clientUuid: null, stopId: 71, customerId: 11, outcomeId: 4, date: today),
      ],
      sales: [_sale(date: today)],
    );

    await serviceFor(() => now).bootstrap();
    final stops = await DriftRouteRepository(db).watchDayStops().first;

    final ana = stops.firstWhere((s) => s.customer.id == 'cust-uuid-11');
    expect(ana.visit?.outcome?.id, 4);
    expect(ana.visit?.hasSales, isFalse);
    final beto = stops.firstWhere((s) => s.customer.id == 'cust-uuid-12');
    expect(beto.visit?.outcome, isNull);
    expect(beto.visit?.salesTotal, 2700);
    expect(beto.visit?.saleMethods, [PaymentMethod.credit]);
  });
}
