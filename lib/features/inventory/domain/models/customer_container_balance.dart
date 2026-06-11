import 'package:flutter/foundation.dart';

@immutable
class CustomerContainerBalance {
  const CustomerContainerBalance({
    required this.customerId,
    required this.containerType,
    required this.quantity,
  });

  final String customerId;
  final String containerType; // 'BIDON_20L' | 'SIFON_2L'

  /// Current number of containers at the customer's location.
  final int quantity;
}
