# 📘 Design System: Journal Trend Analyzer

Tài liệu này quy định các tiêu chuẩn về giao diện (UI) và trải nghiệm người dùng (UX) cho ứng dụng di động **Journal Trend Analyzer** trên nền tảng Flutter. Việc tuân thủ hệ thống thiết kế này đảm bảo ứng dụng có giao diện nhất quán, mang tính học thuật cao và hiển thị số liệu trực quan.

---

## 🎨 1. Hệ màu sắc (Color Palette)

Hệ màu sử dụng các tông xanh dương đậm làm chủ đạo để tạo cảm giác nghiên cứu khoa học, kết hợp với các màu nhấn nổi bật phục vụ cho việc hiển thị biểu đồ và số liệu phân tích.

| Loại màu | Mã Hex | Tên màu | Vai trò trong ứng dụng Flutter |
| :--- | :--- | :--- | :--- |
| **Primary** | `#1A365D` | Navy Đậm | Thanh AppBar, nút bấm chính, tiêu đề lớn. |
| **Secondary** | `#2B6CB0` | Xanh Biển | Icon, các tab được chọn, liên kết URL/DOI. |
| **Accent** | `#DD6B20` | Cam Đất | Đường line quan trọng trên biểu đồ, các chỉ số "Top". |
| **Chart Line**| `#319795` | Xanh Mint | Thành phần phụ trên biểu đồ cột hoặc đường. |
| **Background**| `#F7FAFC` | Xám Trắng | Nền của toàn bộ ứng dụng (Scaffold Background). |
| **Surface** | `#FFFFFF` | Trắng Tinh | Nền của các tấm thẻ (Cards), Ô tìm kiếm. |
| **Error** | `#E53E3E` | Đỏ Cảnh báo | Trạng thái lỗi khi gọi API thất bại. |
| **Success** | `#38A169` | Xanh Lá | Trạng thái tải dữ liệu thành công, thông báo. |

### Màu chữ (Text Colors)
* **Text Primary (`#2D3748`):** Chữ chính (Tiêu đề bài báo, tên tác giả, nội dung abstract). Tránh dùng màu đen tuyền (`#000000`) trên thiết bị di động để giảm mỏi mắt.
* **Text Secondary (`#718096`):** Chữ phụ (Năm xuất bản, số trích dẫn nhỏ, ghi chú).
* **Text On Primary (`#FFFFFF`):** Chữ hiển thị trên nền tối (Chữ trên AppBar hoặc trên Nút bấm).

---

## ✍️ 2. Hệ Typography (Định dạng chữ)

Font chữ mặc định khuyến nghị: **Inter** hoặc **Roboto** (sạch sẽ, độ hiển thị cao trên màn hình điện thoại).

* **Display Large (Số liệu Dashboard):** `28.0sp` | **Bold** | Màu `Primary` | *Dùng cho các con số thống kê lớn.*
* **Headline Large (Tiêu đề màn hình):** `22.0sp` | **Bold** | Màu `Text Primary` | *Dùng cho tiêu đề các màn hình chính.*
* **Title Medium (Tiêu đề bài báo):** `16.0sp` | **SemiBold** | Màu `Text Primary` | *Dùng cho tên bài báo trong danh sách/chi tiết.*
* **Body Medium (Nội dung văn bản):** `14.0sp` | **Regular** | Màu `Text Primary` | *Dùng cho đoạn Abstract (Line height: 1.45).*
* **Body Small (Chú thích phụ):** `12.0sp` | **Regular** | Màu `Text Secondary` | *Dùng cho năm, tên tạp chí phụ.*
* **Label Large (Chữ trên nút bấm):** `14.0sp` | **SemiBold** | Màu `Text On Primary` | *Dùng cho Text trong ElevatedButton.*

---

## 🔲 3. Hình khối & Bố cục (Shapes & Spacing)

Để giao diện cân đối trên mọi kích thước màn hình mobile, áp dụng quy chuẩn khoảng cách theo **hệ số 8**:

### Khoảng cách (Spacing)
* `spacingXSmall` = `4.0` (Khoảng cách icon và chữ nhỏ)
* `spacingSmall` = `8.0` (Khoảng cách giữa các dòng text nhỏ)
* `spacingMedium` = `16.0` (Padding chuẩn viền màn hình và trong lòng Card)
* `spacingLarge` = `24.0` (Khoảng cách giữa các khối nội dung lớn)

### Bo góc (Border Radius)
* `radiusSmall` = `8.0` (Áp dụng cho các nút bấm - Buttons)
* `radiusMedium` = `12.0` (Áp dụng cho Ô tìm kiếm, Thẻ bài báo, Khối biểu đồ)
* `radiusLarge` = `20.0` (Áp dụng cho các hộp thoại BottomSheet, Dialog)

### Đổ bóng (Card Shadow)
Để các thành phần nổi bật trên nền xám trắng (`#F7FAFC`), sử dụng hiệu ứng bóng mờ nhẹ sau trên các container:
* `Color: Colors.black.withOpacity(0.04)`
* `BlurRadius: 10`
* `Offset: Offset(0, 4)`

---

## 📊 4. Quy chuẩn cấu trúc thành phần giao diện (UI Components)

### 🔍 Màn hình Tìm kiếm (Search Screen)
* **Thanh tìm kiếm:** Viền bo góc `12.0`, có biểu tượng kính lúp màu `Secondary`. Trạng thái chờ hiển thị hiệu ứng Shimmer Loading nhẹ nhàng.
* **Thẻ bài báo (Publication Card):** Thiết kế dạng khối trắng nền xám. Tiêu đề hiển thị tối đa 2 dòng (Sử dụng `TextOverflow.ellipsis`). Góc dưới bên phải có một thẻ nhỏ (Badge) màu nền xanh nhạt hiện số lượt trích dẫn: `🔥 142 citations`.

### 📈 Màn hình Dashboard & Biểu đồ (Dashboard & Trend Screen)
* **Thẻ số liệu tổng quan:** Chia lưới 2 cột (Grid), mỗi ô chứa một biểu tượng nhỏ, tên chỉ số (Xám) và con số tổng to đậm (Primary).
* **Biểu đồ đường (Xu hướng năm):** Trục X hiển thị năm, Trục Y hiển thị số bài báo. Đường biểu đồ dùng màu `Primary` phối gradient mờ đổ xuống dưới.
* **Biểu đồ cột (Top Tạp chí/Tác giả):** Khuyến nghị dùng **biểu đồ cột nằm ngang (Horizontal Bar Chart)** để hiển thị trọn vẹn tên tạp chí/tác giả dài mà không bị che khuất trên màn hình di động.

### 📄 Màn hình Chi tiết (Detail Screen)
* Thông tin tiêu đề nằm trên cùng, font chữ lớn.
* Nút **Mở DOI** nổi bật bằng màu `Secondary`, có icon liên kết ngoài.
* Đoạn văn **Abstract** phải căn lề đều hai bên (`TextAlign.justify`), khoảng cách dòng rộng rãi (`height: 1.45`) để nâng cao trải nghiệm đọc tài liệu dài.

---

## 🛠️ 5. Mã nguồn triển khai nhanh trong Flutter (`app_theme.dart`)

Cả nhóm tạo file `lib/core/theme/app_theme.dart` và dán đoạn mã sau vào để cấu hình toàn cục:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1A365D);
  static const Color secondary = Color(0xFF2B6CB0);
  static const Color background = Color(0xFFF7FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(primary: primary, secondary: secondary, surface: surface),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: Colors.black.withOpacity(0.03)),
        ),
      ),
    );
  }
}