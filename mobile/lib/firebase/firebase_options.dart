import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AppFirebaseOptions {
  AppFirebaseOptions._();

  static const webClientId = String.fromEnvironment(
    'FIREBASE_WEB_CLIENT_ID',
    defaultValue:
        '1077885962572-2ujrlp6mrlrf84dehfbs33gqbbpj1tqf.apps.googleusercontent.com',
  );
  static const androidClientId = String.fromEnvironment(
    'FIREBASE_ANDROID_CLIENT_ID',
  );
  static const iosClientId = String.fromEnvironment('FIREBASE_IOS_CLIENT_ID');
  static const macosClientId = String.fromEnvironment(
    'FIREBASE_MACOS_CLIENT_ID',
  );

  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static FirebaseOptions? get currentPlatform {
    final apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    final appId = _platformValue(
      android: const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
      ios: const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
      macos: const String.fromEnvironment('FIREBASE_MACOS_APP_ID'),
      web: const String.fromEnvironment('FIREBASE_WEB_APP_ID'),
    );
    final messagingSenderId = String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    );
    final projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

    if ([apiKey, appId, messagingSenderId, projectId].any(_isBlank)) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: _nullIfBlank(
        const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      ),
      storageBucket: _nullIfBlank(
        const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      ),
      iosBundleId: _nullIfBlank(
        const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
      ),
      androidClientId: _nullIfBlank(androidClientId),
      iosClientId: _nullIfBlank(iosClientId),
    );
  }

  static String? get googleClientId {
    final value = _platformValue(
      android: androidClientId,
      ios: iosClientId,
      macos: macosClientId,
      web: webClientId,
    );
    return _nullIfBlank(value);
  }

  static String? get googleServerClientId {
    final explicit = _nullIfBlank(serverClientId);
    if (explicit != null) {
      return explicit;
    }
    return _nullIfBlank(webClientId);
  }

  static String _platformValue({
    required String android,
    required String ios,
    required String macos,
    required String web,
  }) {
    if (kIsWeb) {
      return web;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => macos,
      _ => '',
    };
  }

  static bool _isBlank(String value) => value.trim().isEmpty;

  static String? _nullIfBlank(String value) =>
      _isBlank(value) ? null : value.trim();
}
