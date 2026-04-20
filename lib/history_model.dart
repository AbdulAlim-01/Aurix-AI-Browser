import 'package:uuid/uuid.dart';

class HistoryModel {
  final String id;
  final String url;
  final String? title;
  final DateTime visitedAt;

  HistoryModel({
    String? id,
    required this.url,
    this.title,
    required this.visitedAt,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'visited_at': visitedAt.toIso8601String(),
    };
  }

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id'],
      url: map['url'],
      title: map['title'],
      visitedAt: DateTime.parse(map['visited_at']),
    );
  }
}
