class BookmarkModel {
  final String id;
  final String userId;
  final String? title;
  final String url;
  final String? faviconUrl;
  final DateTime createdAt;

  BookmarkModel({
    required this.id,
    required this.userId,
    this.title,
    required this.url,
    this.faviconUrl,
    required this.createdAt,
  });

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      url: map['url'],
      faviconUrl: map['favicon_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}