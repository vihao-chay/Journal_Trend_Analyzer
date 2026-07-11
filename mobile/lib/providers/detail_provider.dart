import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class DetailProvider extends ChangeNotifier {
  // Thực thể kết nối dịch vụ Firebase Analytics đám mây
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Hàm xử lý mở liên kết DOI gốc của bài báo khoa học trên trình duyệt web của điện thoại
  Future<void> openDoiLink(String? doiUrl) async {
    if (doiUrl == null || doiUrl.isEmpty) {
      print("⚠️ Không có link DOI cho bài báo này.");
      return;
    }

    final Uri url = Uri.parse(doiUrl);
    try {
      // Gọi thư viện mở trình duyệt ngoài hệ thống (Chrome, Safari,...)
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        print("🎯 Mở thành công link DOI: $doiUrl");
      } else {
        throw 'Không thể kích hoạt liên kết $doiUrl';
      }
    } catch (e) {
      print('❌ [DetailProvider Error] Lỗi mở trình duyệt: $e');
    }
  }

  /// ✨ [MỤC TIÊU LAB 3]: Cài đặt Log sự kiện Firebase Analytics 'view_publication'
  /// Hàm này tự động kích hoạt khi người dùng nhấn xem chi tiết một bài báo bất kỳ
  Future<void> logViewPublication({required String paperTitle, required String journalName}) async {
    try {
      await _analytics.logEvent(
        name: 'view_publication',
        parameters: {
          // Firebase Analytics giới hạn parameter tối đa 100 ký tự để tối ưu bộ nhớ
          'paper_title': paperTitle.length > 100 ? paperTitle.substring(0, 100) : paperTitle,
          'journal_name': journalName.length > 100 ? journalName.substring(0, 100) : journalName,
        },
      );
      print("🎯 [Analytics] Đã ghi nhận sự kiện 'view_publication' cho bài báo: $paperTitle");
    } catch (e) {
      print('❌ [Analytics Error] Không thể log sự kiện: $e');
    }
  }
}