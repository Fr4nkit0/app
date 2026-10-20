import 'package:app/features/customers/domain/models/customer.dart';
import 'stop_status.dart';

class RouteStop {
  final String id;
  final Customer customer;
  final StopStatus status;
  final DateTime scheduledAt;

  /// False when the server gave the stop no scheduled time.
  final bool hasScheduledTime;

  const RouteStop({
    required this.id,
    required this.customer,
    required this.status,
    required this.scheduledAt,
    this.hasScheduledTime = true,
  });

  RouteStop copyWith({StopStatus? status}) => RouteStop(
    id: id,
    customer: customer,
    status: status ?? this.status,
    scheduledAt: scheduledAt,
    hasScheduledTime: hasScheduledTime,
  );
}
