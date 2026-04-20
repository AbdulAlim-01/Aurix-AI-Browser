import 'dart:convert';

class DownloadModel {
  final String id;
  final String url;
  final String filename;
  final String status; // 'downloading', 'completed', 'failed'
  final String? filePath;
  final DateTime createdAt;

  DownloadModel({
    required this.id,
    required this.url,
    required this.filename,
    required this.status,
    this.filePath,
    required this.createdAt,
  });

  factory DownloadModel.fromMap(Map<String, dynamic> map) {
    return DownloadModel(
      id: map['id'],
      url: map['url'],
      filename: map['filename'],
      status: map['status'],
      filePath: map['file_path'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'status': status,
      'file_path': filePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  factory DownloadModel.fromJson(String source) => DownloadModel.fromMap(json.decode(source));
}
