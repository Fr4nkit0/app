import 'package:flutter/foundation.dart';

@immutable
class ContainerMovement {
  const ContainerMovement({
    required this.id,
    required this.customerId,
    required this.containerType,
    required this.deliveredQuantity,
    required this.returnedQuantity,
    required this.createdAt,
    this.visitId,
    this.routeId,
  });

  final String id;
  final String customerId;
  final String containerType; // 'BIDON_20L' | 'SIFON_2L'
  final int deliveredQuantity;
  final int returnedQuantity;
  final DateTime createdAt;
  final String? visitId;
  final String? routeId;

  /// Net change in containers at the customer's location.
  /// Positive = more containers delivered, negative = more returned.
  int get netQuantity => deliveredQuantity - returnedQuantity;
}
