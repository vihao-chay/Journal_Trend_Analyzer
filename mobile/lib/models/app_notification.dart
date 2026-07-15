enum AppNotificationSource { foreground, background, openedApp, initialMessage }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.source,
    this.data = const <String, String>{},
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final AppNotificationSource source;
  final Map<String, String> data;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  AppNotification copyWith({
    String? title,
    String? body,
    DateTime? receivedAt,
    AppNotificationSource? source,
    Map<String, String>? data,
    DateTime? readAt,
    bool clearReadAt = false,
  }) {
    return AppNotification(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      source: source ?? this.source,
      data: data ?? this.data,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'receivedAt': receivedAt.toUtc().toIso8601String(),
      'source': source.name,
      'data': data,
      'readAt': readAt?.toUtc().toIso8601String(),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = <String, String>{};
    if (rawData is Map) {
      for (final entry in rawData.entries) {
        data[entry.key.toString()] = entry.value.toString();
      }
    }

    final rawSource = json['source']?.toString();
    final source = AppNotificationSource.values.firstWhere(
      (item) => item.name == rawSource,
      orElse: () => AppNotificationSource.background,
    );

    return AppNotification(
      id: _nonEmptyString(json['id']) ??
          'notification_${DateTime.now().microsecondsSinceEpoch}',
      title: _nonEmptyString(json['title']) ?? 'Research notification',
      body: _nonEmptyString(json['body']) ?? '',
      receivedAt: DateTime.tryParse(json['receivedAt']?.toString() ?? '') ??
          DateTime.now(),
      source: source,
      data: Map<String, String>.unmodifiable(data),
      readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
    );
  }

  static String? _nonEmptyString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
