class UserPreferences {
  const UserPreferences({
    required this.userId,
    this.plan,
    this.budget = 0,
    this.companion,
    this.place,
    this.minutes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String? plan;
  final double budget;
  final String? companion;
  final String? place;
  final double minutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['user_id'] as String? ?? '',
      plan: json['plan'] as String?,
      budget: (json['budget'] as num?)?.toDouble() ?? 0,
      companion: json['companion'] as String?,
      place: json['place'] as String?,
      minutes: (json['minutes'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'user_id': userId,
    'plan': plan,
    'budget': budget,
    'companion': companion,
    'place': place,
    'minutes': minutes,
  };
}
