import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  // Tạo một instance (thực thể) của Firebase Remote Config
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Hàm khởi tạo và cấu hình ban đầu
  Future<void> initialize() async {
    try {
      // 1. Đặt giá trị mặc định trong code (Phòng trường hợp điện thoại mất mạng)
      await _remoteConfig.setDefaults(<String, dynamic>{
        'max_display_items': 10, // Mặc định chỉ hiển thị 10 mục
      });
      
      // 2. Cấu hình thời gian tải lại dữ liệu (Fetch và Activate)
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1), // Quá 1 phút không tải được thì hủy
        minimumFetchInterval: const Duration(minutes: 5), // Cứ sau 5 phút cho phép tải lại bản mới trên Cloud
      ));
      
      // 3. Tiến hành kéo dữ liệu từ Firebase Server về và kích hoạt sử dụng
      await _remoteConfig.fetchAndActivate();
      print("🎯 [Remote Config] Khởi tạo thành công. Giá trị hiện tại: ${getMaxDisplayItems()}");
    } catch (e) {
      print('❌ [Remote Config] Lỗi khởi tạo: $e');
    }
  }

  // Hàm helper để các Dev khác trong nhóm gọi lấy giá trị (Trả về kiểu số nguyên int)
  int getMaxDisplayItems() {
    return _remoteConfig.getInt('max_display_items');
  }
}