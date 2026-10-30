/// Outcome catalog entry, identified by its server id.
class VisitOutcome {
  const VisitOutcome({
    required this.id,
    this.code,
    required this.name,
    required this.triggersReschedule,
  });

  final int id;
  final String? code;
  final String name;
  final bool triggersReschedule;
}
