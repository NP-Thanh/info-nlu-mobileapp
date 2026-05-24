class AppNotification {
  final int id;
  final String title;
  final String content;
  final String? type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.content,
    this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) return DateTime.parse(value);
    if (value is List && value.length >= 3) {
      final y = (value[0] as num).toInt();
      final m = (value[1] as num).toInt();
      final d = (value[2] as num).toInt();
      final h = value.length > 3 ? (value[3] as num).toInt() : 0;
      final min = value.length > 4 ? (value[4] as num).toInt() : 0;
      final sec = value.length > 5 ? (value[5] as num).toInt() : 0;
      return DateTime(y, m, d, h, min, sec);
    }
    return DateTime.now();
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      content: content,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
