import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../firebase/firebase_bootstrap.dart';
import '../firebase/notification_inbox_store.dart';
import '../models/app_notification.dart';

class DashboardReportData {
  const DashboardReportData({
    required this.topic,
    required this.totalPublications,
    required this.averageCitations,
    required this.topJournals,
    required this.topKeywords,
    required this.recentSearches,
  });

  final String topic;
  final int totalPublications;
  final double averageCitations;
  final List<String> topJournals;
  final List<String> topKeywords;
  final List<String> recentSearches;
}

class FirebaseFeaturesViewModel extends ChangeNotifier {
  FirebaseFeaturesViewModel({
    NotificationInboxStore? inboxStore,
    bool autoInitialize = true,
  }) {
    _inboxStore = inboxStore;
    if (autoInitialize) {
      initialize();
    }
  }

  NotificationInboxStore? _inboxStore;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  NotificationInboxStore get _store => _inboxStore ??= NotificationInboxStore();

  bool isInitializing = false;
  bool isFirebaseAvailable = false;
  bool isRemoteConfigLoading = false;
  bool isExporting = false;
  bool isMessagingReady = false;
  String? errorMessage;
  String? fcmToken;
  String? notificationPermissionLabel;
  String? lastExportedUrl;
  String? lastPdfPath;

  int maxJournals = 10;
  int maxKeywords = 12;
  List<AppNotification> notifications = const [];

  int get unreadNotificationCount =>
      notifications.where((notification) => !notification.isRead).length;

  Future<void> initialize() async {
    if (isInitializing) {
      return;
    }

    isInitializing = true;
    errorMessage = null;
    notifyListeners();

    notifications = await _store.load();

    try {
      final app = await FirebaseBootstrap.initialize();
      isFirebaseAvailable = app != null;
      if (app == null) {
        errorMessage =
            'Firebase chưa sẵn sàng. Kiểm tra google-services.json hoặc dart-define Firebase.';
        return;
      }

      await Future.wait<void>([refreshRemoteConfig(), _initializeMessaging()]);
    } catch (error, stackTrace) {
      errorMessage = 'Không thể khởi tạo Firebase features.';
      await _recordNonFatal(error, stackTrace, reason: 'firebase_init');
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> refreshRemoteConfig() async {
    isRemoteConfigLoading = true;
    notifyListeners();

    try {
      await FirebaseBootstrap.requireInitialized();
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults(const <String, dynamic>{
        'max_journals': 10,
        'max_keywords': 12,
      });
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ),
      );
      await remoteConfig.fetchAndActivate();
      maxJournals = _boundedConfigInt(remoteConfig, 'max_journals', 10, 3, 25);
      maxKeywords = _boundedConfigInt(remoteConfig, 'max_keywords', 12, 4, 30);
      errorMessage = null;
    } catch (error, stackTrace) {
      errorMessage = 'Không thể tải Remote Config.';
      await _recordNonFatal(error, stackTrace, reason: 'remote_config');
    } finally {
      isRemoteConfigLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    notifications = await _store.load();
    notifyListeners();
  }

  Future<void> markNotificationRead(String notificationId) async {
    notifications = await _store.markRead(notificationId);
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    notifications = await _store.markAllRead();
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    await _store.clear();
    notifications = const [];
    notifyListeners();
  }

  Future<String?> exportReportPdf(DashboardReportData data) async {
    isExporting = true;
    errorMessage = null;
    lastExportedUrl = null;
    notifyListeners();

    try {
      await FirebaseBootstrap.requireInitialized();
      final file = await _writeReportPdf(data);
      lastPdfPath = file.path;

      final fileName =
          'journal-trend-${DateTime.now().millisecondsSinceEpoch}.pdf';
      final reference = FirebaseStorage.instance.ref().child(
        'exports/$fileName',
      );
      await reference.putFile(
        file,
        SettableMetadata(contentType: 'application/pdf'),
      );
      final url = await reference.getDownloadURL();
      lastExportedUrl = url;
      await trackExportPdf(topic: data.topic, storageUrl: url);
      return url;
    } catch (error, stackTrace) {
      errorMessage = 'Không thể xuất hoặc upload PDF lên Firebase Storage.';
      await _recordNonFatal(error, stackTrace, reason: 'export_pdf');
      return null;
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  Future<void> trackLogin({String method = 'google'}) {
    return _logEvent('login', parameters: <String, Object>{'method': method});
  }

  Future<void> trackLogout() {
    return _logEvent('logout');
  }

  Future<void> trackSearchTopic(String topic) {
    return _logEvent(
      'search_topic',
      parameters: <String, Object>{
        'keyword': _limit(topic),
        'topic': _limit(topic),
      },
    );
  }

  Future<void> trackViewPublication({
    required String publicationId,
    required String title,
    int? publicationYear,
  }) {
    final parameters = <String, Object>{
      'publication_id': _limit(publicationId),
      'publication_title': _limit(title),
      'title': _limit(title),
    };
    final year = publicationYear;
    if (year != null) {
      parameters['publication_year'] = year;
    }

    return _logEvent('view_publication', parameters: parameters);
  }

  Future<void> trackViewJournal({
    required String journalId,
    required String name,
  }) {
    return _logEvent(
      'view_journal',
      parameters: <String, Object>{
        'journal_id': _limit(journalId),
        'journal_name': _limit(name),
        'name': _limit(name),
      },
    );
  }

  Future<void> trackViewKeyword({
    required String keywordId,
    required String name,
  }) {
    return _logEvent(
      'view_keyword',
      parameters: <String, Object>{
        'keyword_id': _limit(keywordId),
        'keyword': _limit(name),
        'name': _limit(name),
      },
    );
  }

  Future<void> trackExportPdf({required String topic, String? storageUrl}) {
    return _logEvent(
      'export_pdf',
      parameters: <String, Object>{
        'topic': _limit(topic),
        if (storageUrl != null) 'storage_url': _limit(storageUrl),
      },
    );
  }

  Future<void> recordHandledException() {
    return _recordNonFatal(
      StateError('Manual Crashlytics non-fatal test'),
      StackTrace.current,
      reason: 'manual_profile_test',
    );
  }

  Future<void> forceTestCrash() async {
    await FirebaseBootstrap.requireInitialized();
    FirebaseCrashlytics.instance.crash();
  }

  Future<void> _initializeMessaging() async {
    if (!_supportsMessaging) {
      notificationPermissionLabel = 'Nền tảng này không hỗ trợ FCM.';
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    notificationPermissionLabel = settings.authorizationStatus.name;
    fcmToken = await messaging.getToken();
    isMessagingReady = true;

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      await _storeRemoteMessage(
        initialMessage,
        source: AppNotificationSource.initialMessage,
      );
    }

    await _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (message) => _storeRemoteMessage(
        message,
        source: AppNotificationSource.foreground,
      ),
    );

    await _openedSubscription?.cancel();
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) =>
          _storeRemoteMessage(message, source: AppNotificationSource.openedApp),
    );
  }

  Future<void> _storeRemoteMessage(
    RemoteMessage message, {
    required AppNotificationSource source,
  }) async {
    notifications = await _store.upsert(
      appNotificationFromRemoteMessage(message, source: source),
    );
    notifyListeners();
  }

  Future<File> _writeReportPdf(DashboardReportData data) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'Journal Trend Analyzer Report'),
          pw.Text('Topic: ${data.topic}'),
          pw.Text('Total publications: ${data.totalPublications}'),
          pw.Text(
            'Average citations: ${data.averageCitations.toStringAsFixed(2)}',
          ),
          pw.SizedBox(height: 16),
          pw.Header(level: 1, text: 'Top journals'),
          pw.Bullet(text: data.topJournals.isEmpty ? 'No data' : ''),
          for (final journal in data.topJournals.take(10))
            pw.Bullet(text: journal),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'Top keywords'),
          pw.Bullet(text: data.topKeywords.isEmpty ? 'No data' : ''),
          for (final keyword in data.topKeywords.take(12))
            pw.Bullet(text: keyword),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'Recent searches'),
          pw.Bullet(text: data.recentSearches.isEmpty ? 'No data' : ''),
          for (final search in data.recentSearches.take(8))
            pw.Bullet(text: search),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/journal_trend_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await FirebaseBootstrap.requireInitialized();
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (error, stackTrace) {
      await _recordNonFatal(error, stackTrace, reason: 'analytics_$name');
    }
  }

  Future<void> _recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) async {
    if (!isFirebaseAvailable && Firebase.apps.isEmpty) {
      return;
    }

    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Crashlytics recordError failed: $error');
      }
    }
  }

  int _boundedConfigInt(
    FirebaseRemoteConfig remoteConfig,
    String key,
    int fallback,
    int min,
    int max,
  ) {
    final value = remoteConfig.getInt(key);
    if (value == 0) {
      return fallback;
    }
    return value.clamp(min, max).toInt();
  }

  String _limit(String value, {int max = 96}) {
    final trimmed = value.trim();
    if (trimmed.length <= max) {
      return trimmed;
    }
    return trimmed.substring(0, max);
  }

  bool get _supportsMessaging {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    super.dispose();
  }
}
