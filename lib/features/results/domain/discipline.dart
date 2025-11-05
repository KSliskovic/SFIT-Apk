class Discipline {
  final String id;
  final String name;
  final bool isTeam; // true = timski, false = individualni

  const Discipline({required this.id, required this.name, required this.isTeam});

  Discipline copyWith({String? id, String? name, bool? isTeam}) => Discipline(
        id: id ?? this.id,
        name: name ?? this.name,
        isTeam: isTeam ?? this.isTeam,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'isTeam': isTeam,
      };

  static Discipline fromJson(Map<String, dynamic> json) => Discipline(
        id: json['id'] as String,
        name: json['name'] as String,
        isTeam: json['isTeam'] as bool,
      );
}
