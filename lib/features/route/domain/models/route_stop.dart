import 'package:app/features/customers/domain/models/customer.dart';
import 'stop_status.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';

class RouteStop {
  final String id;
  final Customer customer;
  final VisitType visitType;
  final StopStatus status;
  final DateTime scheduledAt;

  const RouteStop({
    required this.id,
    required this.customer,
    required this.visitType,
    required this.status,
    required this.scheduledAt,
  });

  RouteStop copyWith({
    StopStatus? status,
  }) =>
      RouteStop(
        id: id,
        customer: customer,
        visitType: visitType,
        status: status ?? this.status,
        scheduledAt: scheduledAt,
      );
}
