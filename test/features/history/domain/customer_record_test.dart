import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/history/domain/models/customer_record.dart';

void main() {
  final now = DateTime(2026, 10, 31, 15);
  final today = DateTime(2026, 10, 31, 9);

  CustomerRecord record(
    CustomerRecordType type, {
    DateTime? date,
    bool isCancelled = false,
    String? visitId,
    String? saleId,
  }) => CustomerRecord(
    id: 'r-1',
    type: type,
    date: date ?? today,
    isCancelled: isCancelled,
    visitId: visitId,
    saleId: saleId,
  );

  group('isCancellableOn', () {
    test('an off-route sale or debt payment of today can be cancelled', () {
      expect(record(CustomerRecordType.sale).isCancellableOn(now), isTrue);
      expect(record(CustomerRecordType.payment).isCancellableOn(now), isTrue);
    });

    test('a cancelled record cannot', () {
      expect(
        record(CustomerRecordType.sale, isCancelled: true).isCancellableOn(now),
        isFalse,
      );
      expect(
        record(
          CustomerRecordType.payment,
          isCancelled: true,
        ).isCancellableOn(now),
        isFalse,
      );
    });

    test('a record of another day cannot', () {
      final yesterday = DateTime(2026, 10, 30, 23);
      expect(
        record(CustomerRecordType.sale, date: yesterday).isCancellableOn(now),
        isFalse,
      );
      expect(
        record(
          CustomerRecordType.payment,
          date: yesterday,
        ).isCancellableOn(now),
        isFalse,
      );
    });

    test('a record of a visit is cancelled from the visit', () {
      expect(
        record(CustomerRecordType.sale, visitId: 'stop-1').isCancellableOn(now),
        isFalse,
      );
      expect(
        record(
          CustomerRecordType.payment,
          visitId: 'stop-1',
        ).isCancellableOn(now),
        isFalse,
      );
    });

    test('a payment that settled a sale goes with the sale', () {
      expect(
        record(
          CustomerRecordType.payment,
          saleId: 'sale-1',
        ).isCancellableOn(now),
        isFalse,
      );
    });

    test('visits and container movements cannot', () {
      expect(record(CustomerRecordType.visit).isCancellableOn(now), isFalse);
      expect(
        record(CustomerRecordType.containerMovement).isCancellableOn(now),
        isFalse,
      );
    });
  });
}
