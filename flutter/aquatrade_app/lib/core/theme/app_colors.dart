import 'package:flutter/material.dart';

/// Bảng màu Aqua Crystal — nguồn token màu DUY NHẤT của app.
/// Không hardcode Color(0xFF...) trong screen; thêm token mới vào đây.
class AppColors {
  AppColors._();

  // Thương hiệu
  static const Color primary = Color(0xFF13ECC8); // teal chủ đạo
  static const Color onPrimary = Color(0xFF0A1A17); // chữ trên nền teal

  // Nền
  static const Color surface = Color(0xFFF6F8F8); // scaffold background
  static const Color card = Color(0xFFFFFFFF); // nền card
  static const Color dark = Color(0xFF0F172A); // card AI tối / text đậm
  static const Color imagePlaceholder = Color(0xFFEDF6F1); // nền ảnh sản phẩm

  // Chữ
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF1E293B);
  static const Color onDark = Color(0xFFFFFFFF);

  // Trạng thái / chip
  static const Color secondary = Color(0xFF0D9488); // teal đậm phụ
  static const Color secondary10 = Color(0x1A0D9488);
  static const Color tertiary = Color(0xFF3B82F6); // icon xanh dương (Stitch)
  static const Color infoBg = Color(0xFFDBEAFE); // chip "CHỜ DUYỆT"
  static const Color infoText = Color(0xFF1E40AF);
  static const Color neutralBg = Color(0xFFF1F5F9); // chip trung tính

  // Bổ sung cho Market + Seller Onboarding
  static const Color bannerDark = Color(0xFF10221F); // banner dự báo AI (tối)
  static const Color onBannerDark = Color(0xFFF3FBF7); // chữ trên banner tối
  static const Color inputFill = Color(0xFFEDF6F1); // nền input/ô nhập
  static const Color segmentTrack = Color(0xFFF0F4F4); // nền segmented control
  static const Color textMuted = Color(0xFF94A3B8); // slate-400 (label mờ)
  static const Color textStrong = Color(0xFF334155); // slate-700 (chữ đậm vừa)
  static const Color stepInactive = Color(0xFFDCE5E0); // step/nút chưa kích hoạt
  static const Color onPrimaryDeep = Color(0xFF006B59); // chữ teal đậm trên nền teal nhạt

  // Auth (Figma Login 2008:3 / Register 2008:75)
  static const Color authInputFill = Color(0xFFEEEEEE); // nền input Figma #eee
  static const Color authLink = Color(0xFF006565); // link "Forgot" / "Register"
  static const Color authBlob = Color(0xFFE0F2F2); // blob trang trí login
  static const Color authBlobAccent = Color(0xFF76D6D5);

  // Cảnh báo / lỗi (đơn chờ xác nhận, hết hàng...)
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0x1AEF4444); // error 10%
  static const Color errorContainer = Color(0xFFFEE2E2); // chip "GIÁ ĐÃ THAY ĐỔI"
  static const Color onErrorContainer = Color(0xFF991B1B);
  static const Color warning = Color(0xFFD97706); // icon cảnh báo (thiếu số dư)
  static const Color warningBg = Color(0xFFFEF3C7); // vòng vàng nhạt

  // Bổ sung cho Chi tiết sản phẩm + Giỏ hàng
  static const Color surfaceHigh = Color(0xFFE1EAE6); // nút phụ / nền avatar
  static const Color surfaceDim = Color(0xFFD3DCD8); // checkbox disabled
  static const Color tealInk = Color(0xFF005143); // label "GỢI Ý" trên nền teal nhạt

  // Teal biến thể alpha (dùng cho border/nền nhạt/cột biểu đồ)
  static const Color primary05 = Color(0x0D13ECC8); // 5%
  static const Color primary10 = Color(0x1A13ECC8); // 10%
  static const Color primary20 = Color(0x3313ECC8); // 20%
  static const Color primary30 = Color(0x4D13ECC8); // 30%
  static const Color primary40 = Color(0x6613ECC8); // 40%
  static const Color primary50 = Color(0x8013ECC8); // 50%

  // Đường viền
  static const Color borderFaint = primary05;
  static const Color borderSoft = primary10;
}
