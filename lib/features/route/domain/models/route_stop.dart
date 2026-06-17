import 'package:app/features/customers/domain/models/customer.dart';
import 'stop_status.dart';

class RouteStop {
  final String id;
  final Customer customer;
  final StopStatus status;
  final DateTime scheduledAt;

  const RouteStop({
    required this.id,
    required this.customer,
    required this.status,
    required this.scheduledAt,
  });

  RouteStop copyWith({
    StopStatus? status,
  }) =>
      RouteStop(
        id: id,
        customer: customer,
        status: status ?? this.status,
        scheduledAt: scheduledAt,
      );
}
