import 'customer.address.dart';
import 'customer.preference.dart';

class Customer {
  final String id;
  final String name;
  final String? phone;
  final List<CustomerAddress> addresses;
  final List<CustomerPreference> preferences;
  final double debtAmount;
  final bool isFrequent;
  final List<String> productLabels;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    required this.addresses,
    required this.preferences,
    this.debtAmount = 0.0,
    this.isFrequent = false,
    this.productLabels = const [],
  });
}
