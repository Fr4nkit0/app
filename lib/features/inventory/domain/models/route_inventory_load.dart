import 'package:flutter/foundation.dart';

@immutable
class RouteInventoryLoad {
  const RouteInventoryLoad({
    required this.id,
    required this.routeId,
    required this.productId,
    required this.quantity,
    required this.loadedAt,
    this.createdBy,
  });

  final String id;
  final String routeId;
  final String productId;
  final int quantity;
  final DateTime loadedAt;
  final String? createdBy;
}
