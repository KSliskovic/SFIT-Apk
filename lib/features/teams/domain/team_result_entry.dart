class TeamResultEntry {
  final String id;          // tr_<timestamp>
  final String eventId;     // ev_001
  final String discipline;  // npr. "Nogomet 5v5"
  final String teamId;      // tm_...
  final double value;       // npr. vrijeme/bodovi
  final String unit;        // "s", "pts", ...

  const TeamResultEntry({
    required this.id,
    required this.eventId,
    required this.discipline,
    required this.teamId,
    required this.value,
    required this.unit,
  });
}
