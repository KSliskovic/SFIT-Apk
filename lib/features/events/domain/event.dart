import 'package:cloud_firestore/cloud_firestore.dart';

class EventItem {
  final String? id;
  final String title;
  final String? location;
  final DateTime? startAt;
  final DateTime? endAt;
  final String ownerUid;
  final String? description;
  final List<String> disciplines;

  EventItem({
    this.id,
    required this.title,
    this.location,
    this.startAt,
    this.endAt,
    required this.ownerUid,
    this.description,
    List<String>? disciplines,
  }) : disciplines = disciplines ?? const [];

  EventItem copyWith({
    String? id,
    String? title,
    String? location,
    DateTime? startAt,
    DateTime? endAt,
    String? ownerUid,
    String? description,
    List<String>? disciplines,
  }) {
    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      ownerUid: ownerUid ?? this.ownerUid,
      description: description ?? this.description,
      disciplines: disciplines ?? this.disciplines,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'location': location,
    'startAt': startAt,
    'endAt': endAt,
    'ownerUid': ownerUid,
    'description': description,
    'disciplines': disciplines,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory EventItem.fromJson(Map<String, dynamic> json) => EventItem(
    id: json['id'] as String?,
    title: json['title'] as String,
    location: json['location'] as String?,
    startAt: (json['startAt'] is Timestamp)
        ? (json['startAt'] as Timestamp).toDate()
        : json['startAt'] as DateTime?,
    endAt: (json['endAt'] is Timestamp)
        ? (json['endAt'] as Timestamp).toDate()
        : json['endAt'] as DateTime?,
    ownerUid: json['ownerUid'] as String,
    description: json['description'] as String?,
    disciplines: (json['disciplines'] as List?)
        ?.whereType<String>()
        .toList() ??
        const [],
  );
}
