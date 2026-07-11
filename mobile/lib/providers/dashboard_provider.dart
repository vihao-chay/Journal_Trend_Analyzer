import 'package:flutter/material.dart';
import '../models/publication_model.dart';

class DashboardProvider extends ChangeNotifier {
  // Danh sách bài báo gốc nhận từ kết quả tìm kiếm của Dev 1
  List<PublicationModel> _publications = [];
  bool _isLoading = false;

  List<PublicationModel> get publications => _publications;
  bool get isLoading => _isLoading;

  // Hàm này để Dev 1 gọi và truyền dữ liệu sang sau khi họ bấm nút Tìm kiếm thành công
  void updateData(List<PublicationModel> newList) {
    _isLoading = true;
    notifyListeners(); // Báo cho giao diện hiện trạng thái loading (nếu cần)

    _publications = newList;
    
    _isLoading = false;
    notifyListeners(); // Tính toán xong, báo cho giao diện cập nhật số liệu mới ngay lập tức
  }

  // --- 🌟 TẦNG TÍNH TOÁN CÁC CHỈ SỐ DASHBOARD THẦY YÊU CẦU 🌟 ---

  // Chức năng 1: Tính tổng số lượng bài báo tìm được
  int get totalPublications => _publications.length;

  // Chức năng 2: Tính số lượt trích dẫn trung bình (Average Citations)
  double get averageCitations {
    if (_publications.isEmpty) return 0.0;
    
    // Cộng tổng tất cả số trích dẫn của các bài báo lại
    int totalCitations = _publications.fold(0, (sum, item) => sum + item.citedByCount);
    
    // Chia cho tổng số bài để ra trung bình
    return totalCitations / _publications.length;
  }

  // Chức năng 3: Tìm năm hoạt động sôi nổi nhất (Most Active Year)
  int get mostActiveYear {
    if (_publications.isEmpty) return 0;
    
    // Dùng Map để đếm xem mỗi năm xuất hiện bao nhiêu bài báo
    Map<int, int> yearCounts = {};
    for (var pub in _publications) {
      yearCounts[pub.publicationYear] = (yearCounts[pub.publicationYear] ?? 0) + 1;
    }

    // Tìm năm có số lượng bài báo lớn nhất trong Map
    int maxCount = -1;
    int activeYear = 0;
    
    yearCounts.forEach((year, count) {
      if (count > maxCount) {
        maxCount = count;
        activeYear = year;
      }
    });
    
    return activeYear;
  }

  // Chức năng 4: Tìm bài báo có sức ảnh hưởng nhất (Top Influential Paper)
  // Trả về bài viết có số lượt trích dẫn cao nhất để hiển thị nổi bật trên Dashboard
  PublicationModel? get topInfluentialPaper {
    if (_publications.isEmpty) return null;
    
    return _publications.reduce((curr, next) => 
        curr.citedByCount > next.citedByCount ? curr : next
    );
  }
}