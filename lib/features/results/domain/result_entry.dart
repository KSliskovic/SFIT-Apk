class ResultEntry {
  final String id;
  final String eventId;
  final String discipline;  // NOVO
  final String participant;
  final double value;
  final String unit;
  final DateTime createdAt;

  const ResultEntry({
    required this.id,
    required this.eventId,
    required this.discipline,
    required this.participant,
    required this.value,
    required this.unit,
    required this.createdAt,
  });
}
