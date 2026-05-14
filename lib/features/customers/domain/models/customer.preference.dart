class CustomerPreference {
  final String id;
  final int dayOfWeek;
  final String timeWindowStart;
  final String? timeWindowEnd;

  CustomerPreference({
    required this.id,
    required this.dayOfWeek,
    required this.timeWindowStart,
    this.timeWindowEnd,
  });

  CustomerPreference copyWith({
    String? id,
    int? dayOfWeek,
    String? timeWindowStart,
    String? timeWindowEnd,
  }) {
    return CustomerPreference(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeWindowStart: timeWindowStart ?? this.timeWindowStart,
      timeWindowEnd: timeWindowEnd ?? this.timeWindowEnd,
    );
  }
}
