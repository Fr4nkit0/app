/// Outcome catalog entry, identified by its server id.
class VisitOutcome {
  const VisitOutcome({
    required this.id,
    required this.name,
    required this.triggersReschedule,
  });

  final int id;
  final String name;
  final bool triggersReschedule;
}
