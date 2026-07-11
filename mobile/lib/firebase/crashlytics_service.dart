import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> triggerHandledException(dynamic error, StackTrace stackTrace) async {
    try {
      await _crashlytics.recordError(error, stackTrace, reason: 'Handled exception triggered');
      if (kDebugMode) {
        print('Recorded handled exception: $error');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to record exception: $e');
      }
    }
  }

  void triggerFatalCrash() {
    if (kDebugMode) {
      print('Triggering fatal crash for testing purposes.');
    }
    _crashlytics.crash();
  }
}
