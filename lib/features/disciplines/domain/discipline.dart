class Discipline {
  final String id;
  final String name;
  final bool isTeam; // true = timski sport, false = individualni

  Discipline({required this.id, required this.name, required this.isTeam});

  Discipline copyWith({String? id, String? name, bool? isTeam}) => Discipline(
        id: id ?? this.id,
        name: name ?? this.name,
        isTeam: isTeam ?? this.isTeam,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'isTeam': isTeam};

  factory Discipline.fromJson(Map<String, dynamic> j) => Discipline(
        id: j['id'] as String,
        name: j['name'] as String,
        isTeam: (j['isTeam'] as bool?) ?? false,
      );
}
