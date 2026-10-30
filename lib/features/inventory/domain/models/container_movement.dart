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
    this.saleId,
  });

  final String id;
  final String customerId;
  final String containerType; // Catalog code (ContainerType.code)
  final int deliveredQuantity;
  final int returnedQuantity;
  final DateTime createdAt;
  final String? visitId;
  final String? routeId;

  /// The sale it was delivered and returned with; null for a return
  /// without a sale.
  final String? saleId;

  /// This movement, recorded with the sale [saleId].
  ContainerMovement withSale(String saleId) => ContainerMovement(
    id: id,
    customerId: customerId,
    containerType: containerType,
    deliveredQuantity: deliveredQuantity,
    returnedQuantity: returnedQuantity,
    createdAt: createdAt,
    visitId: visitId,
    routeId: routeId,
    saleId: saleId,
  );

  /// Net change in containers at the customer's location.
  /// Positive = more containers delivered, negative = more returned.
  int get netQuantity => deliveredQuantity - returnedQuantity;
}
