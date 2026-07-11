import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class StorageService {
  // Thực thể kết nối Firebase Storage và Analytics đám mây
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Hàm tạo file báo cáo PDF và tự động upload lên Firebase Storage
  /// Trả về đường link URL công khai để tải/xem file nếu thành công
  Future<String?> generateAndUploadReport({
    required String keyword,
    required int totalPubs,
    required double avgCitations,
    required int activeYear,
    required String topPaperTitle,
  }) async {
    try {
      // 1. Sử dụng thư viện 'pdf' để khởi tạo và vẽ nội dung trang báo cáo
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
             crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Tiêu đề báo cáo
              pw.Header(level: 0, text: 'JOURNAL TREND ANALYTICS REPORT'),
              pw.SizedBox(height: 15),
              pw.Text('Research Topic Keyword: "$keyword"', style: pw.TextStyle(fontSize: 16)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              // Đổ các số liệu thô mà bạn (Dev 2) đã tính toán từ Dashboard vào đây
              pw.Text('1. Total Publications Found: $totalPubs', style: pw.TextStyle(fontSize: 14)),
              pw.Text('2. Average Citation Count: ${avgCitations.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('3. Most Active Publication Year: $activeYear', style: pw.TextStyle(fontSize: 14)),
              pw.Text('4. Top Influential Paper Title: "$topPaperTitle"', style: pw.TextStyle(fontSize: 14)),
              
              pw.SizedBox(height: 40),
              pw.Text('Report generated dynamically via Firebase Cloud Storage Service.', 
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10)),
            ],
          ),
        ),
      );

      // 2. Lưu file PDF này vào bộ nhớ tạm (Cache) của điện thoại Android/iOS
      final output = await getTemporaryDirectory();
      // Đổi tên file theo từ khóa tìm kiếm (bỏ khoảng trắng để tránh lỗi đường dẫn URL)
      final fileName = "Report_${keyword.replaceAll(' ', '_')}.pdf";
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      // 3. Khởi tạo đường dẫn lưu trữ trên đám mây Firebase Storage (thư mục reports/)
      final ref = _storage.ref().child('reports/$fileName');
      
      // Tiến hành đẩy file lên Cloud
      UploadTask uploadTask = ref.putFile(file);
      
      // Chờ đợi quá trình upload hoàn tất và lấy đường link URL công khai từ Server trả về
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // ✨ [CÀI ĐẶT FIREBASE ANALYTICS]: Ghi nhận hành động người dùng xuất PDF thành công
      await _analytics.logEvent(
        name: 'export_pdf',
        parameters: {
          'search_keyword': keyword,
          'total_publications': totalPubs,
        },
      );
      print("🎯 [Analytics & Storage] Upload thành công! URL: $downloadUrl");

      return downloadUrl; // Trả về link URL này
    } catch (e) {
      print('❌ [Storage Service Error]: $e');
      return null;
    }
  }
}