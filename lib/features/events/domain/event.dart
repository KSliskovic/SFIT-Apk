import 'package:intl/intl.dart';

class EventItem {
  final String id;
  final String name;
  final DateTime dateTime;
  final List<String> disciplines;
  final String? location;
  final String? description;

  const EventItem({
    required this.id,
    required this.name,
    required this.dateTime,
    this.disciplines = const [],
    this.location,
    this.description,
  });

  /// Formatiran prikaz datuma
  String get dateString {
    return DateFormat('d. MMMM yyyy. • HH:mm', 'hr').format(dateTime);
  }

  /// Pretvori u JSON za lokalnu pohranu
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dateTime': dateTime.toIso8601String(),
        'disciplines': disciplines,
        'location': location,
        'description': description,
      };

  /// Učitaj iz JSON-a
  factory EventItem.fromJson(Map<String, dynamic> json) => EventItem(
        id: json['id'] as String,
        name: json['name'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        disciplines:
            (json['disciplines'] as List?)?.map((e) => e.toString()).toList() ??
                [],
        location: json['location'] as String?,
        description: json['description'] as String?,
      );
}
