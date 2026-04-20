class AiProfile {
  String? id;
  final String userId;
  String profileName;
  String profileType; // 'personal' or 'business'
  String profileContext;
  DateTime? createdAt;

  AiProfile({
    this.id,
    required this.userId,
    required this.profileName,
    required this.profileType,
    required this.profileContext,
    this.createdAt,
  });

  factory AiProfile.fromMap(Map<String, dynamic> map) {
    return AiProfile(
      id: map['id'],
      userId: map['user_id'],
      profileName: map['profile_name'],
      profileType: map['profile_type'],
      profileContext: map['profile_context'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'user_id': userId,
      'profile_name': profileName,
      'profile_type': profileType,
      'profile_context': profileContext,
    };
    if (id != null) {
      map['id'] = id!;
    }
    return map;
  }
}