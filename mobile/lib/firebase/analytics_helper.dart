import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsHelper {
  static FirebaseAnalytics? get _analytics {
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  static Future<void> logViewJournal(String journalName) async {
    try {
      await _analytics?.logEvent(
        name: 'view_journal',
        parameters: {
          'journal_name': journalName,
        },
      );
      if (kDebugMode) {
        print('Analytics event logged: view_journal ($journalName)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log event view_journal: $e');
      }
    }
  }

  static Future<void> logViewKeyword(String keyword) async {
    try {
      await _analytics?.logEvent(
        name: 'view_keyword',
        parameters: {
          'keyword': keyword,
        },
      );
      if (kDebugMode) {
        print('Analytics event logged: view_keyword ($keyword)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log event view_keyword: $e');
      }
    }
  }
}
