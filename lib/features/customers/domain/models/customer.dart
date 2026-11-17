import 'customer.address.dart';
import 'customer.preference.dart';

class Customer {
  final String id;
  final String name;

  /// The server id drivers know the customer by (`#128`); null until the
  /// customer created on the device is first pushed.
  final int? number;
  final String? phone;
  final List<CustomerAddress> addresses;
  final List<CustomerPreference> preferences;
  final double debtAmount;
  final bool isFrequent;
  final List<String> productLabels;

  Customer({
    required this.id,
    required this.name,
    this.number,
    this.phone,
    required this.addresses,
    required this.preferences,
    this.debtAmount = 0.0,
    this.isFrequent = false,
    this.productLabels = const [],
  });
}
