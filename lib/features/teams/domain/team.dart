class Team {
  final String id;          // tm_<timestamp>
  final String eventId;     // ev_001
  final String name;        // npr. FER Zagreb A
  final List<String> members; // ["Ana", "Marko", "Iva"]

  const Team({
    required this.id,
    required this.eventId,
    required this.name,
    required this.members,
  });

  Team copyWith({String? name, List<String>? members}) => Team(
    id: id,
    eventId: eventId,
    name: name ?? this.name,
    members: members ?? this.members,
  );
}
