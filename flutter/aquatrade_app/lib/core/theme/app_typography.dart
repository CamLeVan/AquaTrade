import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Kiểu chữ chuẩn (Inter) khớp design Aqua Crystal.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(TextTheme base) => GoogleFonts.interTextTheme(base);

  // Overline nhỏ in hoa (VD "TỔNG QUAN", label card)
  static final TextStyle overline = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );

  // Tiêu đề lớn ("Xin chào , ...")
  static final TextStyle heading = GoogleFonts.inter(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.75,
    height: 36 / 30,
    color: AppColors.textPrimary,
  );

  // Tiêu đề section in hoa
  static final TextStyle sectionTitle = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.4,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  // Nhãn card nhỏ in hoa
  static final TextStyle cardLabel = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
    height: 15 / 10,
    color: AppColors.textSecondary,
  );

  // Giá trị lớn trong card
  static final TextStyle cardValue = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 28 / 20,
    color: AppColors.textPrimary,
  );

  static final TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 20 / 14,
    color: AppColors.textSecondary,
  );

  static final TextStyle itemTitle = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    height: 16 / 12,
    color: AppColors.textPrimary,
  );

  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    height: 15 / 10,
    color: AppColors.textSecondary,
  );

  static final TextStyle chip = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    height: 15 / 10,
  );
}
