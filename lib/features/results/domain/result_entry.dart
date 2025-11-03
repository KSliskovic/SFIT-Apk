// lib/features/results/domain/result_entry.dart
class TableRowEntry {
  final String id;
  final String name;
  final int played;
  final int wins;
  final int losses;
  final int draws;
  final int points;

  const TableRowEntry({
    required this.id,
    required this.name,
    required this.played,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.points,
  });

  TableRowEntry copyWith({
    String? id,
    String? name,
    int? played,
    int? wins,
    int? losses,
    int? draws,
    int? points,
  }) {
    return TableRowEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      played: played ?? this.played,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      points: points ?? this.points,
    );
  }
}
