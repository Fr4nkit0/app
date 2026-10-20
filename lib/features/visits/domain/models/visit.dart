import 'package:app/features/visits/domain/models/visit_type.dart';

class Visit {
  final String visitId;
  final String routeStopId;
  final String customerId;
  final VisitType visitType;
  final int? outcomeId;
  final DateTime arrivedAt;
  final String? observations;
  final double amountCollected;

  const Visit({
    required this.visitId,
    required this.routeStopId,
    required this.customerId,
    required this.visitType,
    this.outcomeId,
    required this.arrivedAt,
    this.observations,
    this.amountCollected = 0,
  });
}
