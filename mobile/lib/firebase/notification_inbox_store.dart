import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';

const notificationInboxPreferenceKey = 'firebase_notification_inbox_v1';

class NotificationInboxStore {
  NotificationInboxStore({
    SharedPreferencesAsync? preferences,
    this.maximumItems = 100,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  final int maximumItems;
  Future<void> _pendingOperation = Future<void>.value();

  Future<List<AppNotification>> load() {
    return _serialize(() async {
      final raw = await _preferences.getString(notificationInboxPreferenceKey);
      if (raw == null || raw.trim().isEmpty) {
        return const <AppNotification>[];
      }

      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) {
          return const <AppNotification>[];
        }

        final notifications = <AppNotification>[];
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            notifications.add(AppNotification.fromJson(item));
          } else if (item is Map) {
            notifications.add(
              AppNotification.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
        notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
        return List<AppNotification>.unmodifiable(notifications);
      } on FormatException {
        return const <AppNotification>[];
      }
    });
  }

  Future<List<AppNotification>> upsert(AppNotification notification) {
    return _serialize(() async {
      final notifications = await _loadWithoutQueue();
      final existingIndex = notifications.indexWhere(
        (item) => item.id == notification.id,
      );

      if (existingIndex < 0) {
        notifications.add(notification);
      } else {
        final existing = notifications[existingIndex];
        notifications[existingIndex] = AppNotification(
          id: existing.id,
          title: notification.title.trim().isEmpty
              ? existing.title
              : notification.title,
          body: notification.body.trim().isEmpty
              ? existing.body
              : notification.body,
          receivedAt: existing.receivedAt.isBefore(notification.receivedAt)
              ? existing.receivedAt
              : notification.receivedAt,
          source: notification.source,
          data: Map<String, String>.unmodifiable(<String, String>{
            ...existing.data,
            ...notification.data,
          }),
          readAt: notification.readAt ?? existing.readAt,
        );
      }

      notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      if (notifications.length > maximumItems) {
        notifications.removeRange(maximumItems, notifications.length);
      }
      await _saveWithoutQueue(notifications);
      return List<AppNotification>.unmodifiable(notifications);
    });
  }

  Future<List<AppNotification>> markRead(String notificationId) {
    return _serialize(() async {
      final notifications = await _loadWithoutQueue();
      final now = DateTime.now();
      for (var index = 0; index < notifications.length; index++) {
        final notification = notifications[index];
        if (notification.id == notificationId && !notification.isRead) {
          notifications[index] = notification.copyWith(readAt: now);
          break;
        }
      }
      await _saveWithoutQueue(notifications);
      return List<AppNotification>.unmodifiable(notifications);
    });
  }

  Future<List<AppNotification>> markAllRead() {
    return _serialize(() async {
      final notifications = await _loadWithoutQueue();
      final now = DateTime.now();
      final updated = notifications
          .map(
            (item) => item.isRead ? item : item.copyWith(readAt: now),
          )
          .toList(growable: false);
      await _saveWithoutQueue(updated);
      return List<AppNotification>.unmodifiable(updated);
    });
  }

  Future<void> clear() {
    return _serialize(
      () => _preferences.remove(notificationInboxPreferenceKey),
    );
  }

  Future<List<AppNotification>> _loadWithoutQueue() async {
    final raw = await _preferences.getString(notificationInboxPreferenceKey);
    if (raw == null || raw.trim().isEmpty) {
      return <AppNotification>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <AppNotification>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => AppNotification.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on FormatException {
      return <AppNotification>[];
    }
  }

  Future<void> _saveWithoutQueue(List<AppNotification> notifications) {
    final encoded = jsonEncode(
      notifications.map((item) => item.toJson()).toList(growable: false),
    );
    return _preferences.setString(notificationInboxPreferenceKey, encoded);
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _pendingOperation = _pendingOperation.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

AppNotification appNotificationFromRemoteMessage(
  RemoteMessage message, {
  required AppNotificationSource source,
}) {
  final data = <String, String>{};
  for (final entry in message.data.entries) {
    data[entry.key] = entry.value.toString();
  }

  final title = _firstNonEmpty(<Object?>[
        message.notification?.title,
        data['title'],
        data['notification_title'],
      ]) ??
      'Research notification';
  final body = _firstNonEmpty(<Object?>[
        message.notification?.body,
        data['body'],
        data['message'],
      ]) ??
      '';
  final receivedAt = message.sentTime ?? DateTime.now();
  final isOpened = source == AppNotificationSource.openedApp ||
      source == AppNotificationSource.initialMessage;

  return AppNotification(
    id: _firstNonEmpty(<Object?>[message.messageId]) ??
        _fallbackMessageId(message, title, body, receivedAt),
    title: title,
    body: body,
    receivedAt: receivedAt,
    source: source,
    data: Map<String, String>.unmodifiable(data),
    readAt: isOpened ? DateTime.now() : null,
  );
}

String? _firstNonEmpty(Iterable<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) {
      return text;
    }
  }
  return null;
}

String _fallbackMessageId(
  RemoteMessage message,
  String title,
  String body,
  DateTime receivedAt,
) {
  final entries = message.data.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final input = <String>[
    receivedAt.millisecondsSinceEpoch.toString(),
    message.from ?? '',
    title,
    body,
    ...entries.map((entry) => '${entry.key}=${entry.value}'),
  ].join('|');

  var hash = 0x811c9dc5;
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return 'fcm_${receivedAt.millisecondsSinceEpoch}_${hash.toRadixString(16)}';
}
