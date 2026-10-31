import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/widgets/customer_history_list.dart';
import 'package:app/features/history/domain/models/customer_record.dart';

void main() {
  final now = DateTime(2026, 10, 31, 15);
  final today = DateTime(2026, 10, 31, 9);

  late List<String> cancelledSales;
  late List<String> cancelledPayments;

  setUp(() {
    cancelledSales = [];
    cancelledPayments = [];
  });

  Future<void> pump(WidgetTester tester, List<CustomerRecord> records) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CustomerHistoryList(
                records: records,
                containerLabels: const {},
                now: now,
                onCancelSale: cancelledSales.add,
                onCancelPayment: cancelledPayments.add,
              ),
            ),
          ),
        ),
      );

  testWidgets('an off-route sale and debt payment of today offer to be '
      'cancelled', (tester) async {
    await pump(tester, [
      CustomerRecord(
        id: 'sale-1',
        type: CustomerRecordType.sale,
        date: today,
        amount: 300,
      ),
      CustomerRecord(
        id: 'pay-1',
        type: CustomerRecordType.payment,
        date: today,
        amount: 250,
      ),
    ]);

    await tester.tap(find.text('Anular venta'));
    await tester.tap(find.text('Anular cobro'));

    expect(cancelledSales, ['sale-1']);
    expect(cancelledPayments, ['pay-1']);
  });

  testWidgets('cancelled, old, visit and sale-settling records offer '
      'nothing', (tester) async {
    await pump(tester, [
      CustomerRecord(
        id: 'cancelled',
        type: CustomerRecordType.sale,
        date: today,
        isCancelled: true,
      ),
      CustomerRecord(
        id: 'old',
        type: CustomerRecordType.sale,
        date: DateTime(2026, 10, 30, 9),
      ),
      CustomerRecord(
        id: 'visit-sale',
        type: CustomerRecordType.sale,
        date: today,
        visitId: 'stop-1',
      ),
      CustomerRecord(
        id: 'settling',
        type: CustomerRecordType.payment,
        date: today,
        saleId: 'old',
      ),
      CustomerRecord(
        id: 'old-payment',
        type: CustomerRecordType.payment,
        date: DateTime(2026, 10, 30, 9),
      ),
    ]);

    expect(find.text('Anular venta'), findsNothing);
    expect(find.text('Anular cobro'), findsNothing);
  });

  testWidgets('a record the office cancelled says so', (tester) async {
    await pump(tester, [
      CustomerRecord(
        id: 'sale-1',
        type: CustomerRecordType.sale,
        date: today,
        isCancelled: true,
        cancelledByAdmin: true,
      ),
      CustomerRecord(
        id: 'pay-1',
        type: CustomerRecordType.payment,
        date: today,
        isCancelled: true,
        cancelledByAdmin: true,
      ),
      CustomerRecord(
        id: 'pay-2',
        type: CustomerRecordType.payment,
        date: today,
        isCancelled: true,
      ),
    ]);

    expect(find.text('Anulada por el administrador'), findsOneWidget);
    expect(find.text('Anulado por el administrador'), findsOneWidget);
    expect(find.text('Anulado'), findsOneWidget);
  });
}
