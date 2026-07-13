import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import 'firebase_feature_exception.dart';
import 'firebase_options.dart';
import 'notification_inbox_store.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      final options = AppFirebaseOptions.currentPlatform;
      if (options == null) {
        await Firebase.initializeApp();
      } else {
        await Firebase.initializeApp(options: options);
      }
    }

    await NotificationInboxStore().upsert(
      appNotificationFromRemoteMessage(
        message,
        source: AppNotificationSource.background,
      ),
    );
  } catch (error) {
    if (kDebugMode) {
      debugPrint('Unable to persist a background FCM message: $error');
    }
  }
}

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<FirebaseApp?>? _initialization;
  static bool _globalHandlersInstalled = false;
  static bool _backgroundHandlerRegistered = false;
  static Object? lastError;

  static bool get isInitialized => Firebase.apps.isNotEmpty;

  static Future<FirebaseApp?> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      _registerBackgroundHandler();
      await _configureCrashlytics();
      _installGlobalErrorHandlers();
      return Firebase.app();
    }

    final pending = _initialization;
    if (pending != null) {
      return pending;
    }

    final future = _initializeFirebase();
    _initialization = future;
    final app = await future;
    if (app == null) {
      _initialization = null;
    }
    return app;
  }

  static Future<FirebaseApp> requireInitialized() async {
    final app = await initialize();
    if (app != null) {
      return app;
    }
    throw FirebaseFeatureException(
      'Firebase is not available. Check google-services.json and the Firebase project configuration.',
      cause: lastError,
    );
  }

  static Future<FirebaseApp?> _initializeFirebase() async {
    try {
      _registerBackgroundHandler();
      final options = AppFirebaseOptions.currentPlatform;
      final app = options == null
          ? await Firebase.initializeApp()
          : await Firebase.initializeApp(options: options);
      lastError = null;
      await _configureCrashlytics();
      _installGlobalErrorHandlers();
      return app;
    } catch (error) {
      lastError = error;
      if (kDebugMode) {
        debugPrint('Firebase bootstrap failed: $error');
      }
      return null;
    }
  }

  static void _registerBackgroundHandler() {
    if (_backgroundHandlerRegistered || !_supportsMessaging) {
      return;
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _backgroundHandlerRegistered = true;
  }

  static Future<void> _configureCrashlytics() async {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Crashlytics is unavailable on this platform: $error');
      }
    }
  }

  static void _installGlobalErrorHandlers() {
    if (_globalHandlersInstalled) {
      return;
    }
    _globalHandlersInstalled = true;

    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      try {
        unawaited(
          FirebaseCrashlytics.instance.recordFlutterFatalError(details),
        );
      } catch (_) {
        // Firebase can be unavailable during a very early framework failure.
      }
      if (previousFlutterHandler != null) {
        previousFlutterHandler(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      try {
        unawaited(
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            fatal: true,
          ),
        );
      } catch (_) {
        // Keep the application error pipeline alive without Firebase.
      }
      previousPlatformHandler?.call(error, stackTrace);
      return true;
    };
  }

  static bool get _supportsMessaging {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}
