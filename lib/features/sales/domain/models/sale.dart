import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';

class Sale {
  final String id;
  final Customer customer;
  final List<SaleItem> items;
  final double total;
  final PaymentMethod paymentMethod;
  final DateTime date;

  const Sale({
    required this.id,
    required this.customer,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.date,
  });
}
