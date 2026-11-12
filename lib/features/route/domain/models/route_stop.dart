import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/visits/domain/models/visit_summary.dart';
import 'stop_status.dart';

class RouteStop {
  final String id;
  final Customer customer;
  final StopStatus status;
  final DateTime scheduledAt;

  /// False when the server gave the stop no scheduled time.
  final bool hasScheduledTime;

  /// Stop this one was rescheduled from, when it was.
  final String? rescheduledFromStopId;

  /// Scheduled time of the stop this one was rescheduled from.
  final DateTime? rescheduledFromAt;

  /// Scheduled time of the stop this one was rescheduled to, when it was.
  final DateTime? rescheduledToAt;

  /// What the visit recorded; null until a visit is recorded at the stop.
  final VisitSummary? visit;

  /// True when the admin scheduled a visit at this stop. It is not an
  /// order: the visit works as any other.
  final bool isRequested;

  /// The admin's note for a requested visit.
  final String? note;

  /// True when the stop was moved to this route to cover another driver.
  final bool isCover;

  /// The owner driver's display name of a covered stop.
  final String? coveredDriverName;

  const RouteStop({
    required this.id,
    required this.customer,
    required this.status,
    required this.scheduledAt,
    this.hasScheduledTime = true,
    this.rescheduledFromStopId,
    this.rescheduledFromAt,
    this.rescheduledToAt,
    this.visit,
    this.isRequested = false,
    this.note,
    this.isCover = false,
    this.coveredDriverName,
  });

  RouteStop copyWith({StopStatus? status}) => RouteStop(
    id: id,
    customer: customer,
    status: status ?? this.status,
    scheduledAt: scheduledAt,
    hasScheduledTime: hasScheduledTime,
    rescheduledFromStopId: rescheduledFromStopId,
    rescheduledFromAt: rescheduledFromAt,
    rescheduledToAt: rescheduledToAt,
    visit: visit,
    isRequested: isRequested,
    note: note,
    isCover: isCover,
    coveredDriverName: coveredDriverName,
  );
}
