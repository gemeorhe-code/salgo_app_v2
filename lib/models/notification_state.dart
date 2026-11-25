class NotificationState {
  const NotificationState({
    this.id = '',
    required this.userId,
    required this.notificationType,
    this.enabled = true,
    this.lastReadAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String notificationType;
  final bool enabled;
  final DateTime? lastReadAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NotificationState.fromJson(Map<String, dynamic> json) {
    return NotificationState(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      notificationType: json['notification_type'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      lastReadAt: DateTime.tryParse(json['last_read_at'] as String? ?? '')
          ?.toUtc(),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> values = <String, dynamic>{
      'user_id': userId,
      'notification_type': notificationType,
      'enabled': enabled,
      'last_read_at': lastReadAt?.toUtc().toIso8601String(),
    };
    if (id.isNotEmpty) values['id'] = id;
    return values;
  }
}
