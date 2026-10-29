import 'package:flutter/foundation.dart';

@immutable
class CustomerContainerBalance {
  const CustomerContainerBalance({
    required this.customerId,
    required this.containerType,
    required this.quantity,
  });

  final String customerId;
  final String containerType; // Catalog code (ContainerType.code)

  /// Current number of containers at the customer's location.
  final int quantity;
}
