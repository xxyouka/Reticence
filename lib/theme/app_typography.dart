
/// App typography built from bundled fonts only.
///
/// Keeping the theme on local fonts prevents Android startup from depending on
/// runtime downloads from Google Fonts.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  // ============================================================
  // 字体族名常量
  //
  // 集中定义所有字体族名，避免在 widget 中硬编码字符串。
  // ============================================================
  static const String caveat = 'Caveat';
  static const String sourceSerif4 = 'SourceSerif4';
  static const String lxgwWenKai = 'LXGWWenKai';
  static const String harmonyOS = 'HarmonyOS Sans SC';
  static const String notoSerifCJK = 'Noto Serif CJK SC';

  /// 中文衬线字体回退链：思源宋体 SemiBold
  static const List<String> serifFallback = [notoSerifCJK];

  /// 中文手写体回退链：霞鹜文楷
  static const List<String> handwritingFallback = [lxgwWenKai];

  /// 中文无衬线字体回退链：HarmonyOS Sans SC
  static const List<String> sansFallback = [harmonyOS];

  /// 亮色模式文字主题
  static TextTheme lightTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: caveat,
        fontFamilyFallback: handwritingFallback,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.inkBlack,
      ),
      headlineMedium: TextStyle(
        fontFamily: caveat,
        fontFamilyFallback: handwritingFallback,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.inkBlack,
      ),
      titleLarge: TextStyle(
        fontFamily: caveat,
        fontFamilyFallback: handwritingFallback,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.inkBlack,
      ),
      bodyLarge: TextStyle(
        fontFamily: sourceSerif4,
        fontFamilyFallback: serifFallback,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.6,
        color: AppColors.inkBlack,
      ),
      bodyMedium: TextStyle(
        fontFamily: sourceSerif4,
        fontFamilyFallback: serifFallback,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: AppColors.inkBlack,
      ),
      labelSmall: TextStyle(
        fontFamily: sourceSerif4,
        fontFamilyFallback: sansFallback,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        color: AppColors.inkBlack,
      ),
    );
  }

  /// 暗色模式文字主题
  static TextTheme darkTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: caveat,
        fontFamilyFallback: handwritingFallback,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.inkWhite,
      ),
      headlineMedium: TextStyle(
        fontFamily: caveat,
        fontFamilyFallback: handwritingFallback,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.inkWhite,
      ),
      titleLarge: TextStyle(
        fontFamily: caveat,
        fontFamilyFallback: handwritingFallback,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.inkWhite,
      ),
      bodyLarge: TextStyle(
        fontFamily: sourceSerif4,
        fontFamilyFallback: serifFallback,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.6,
        color: AppColors.inkWhite,
      ),
      bodyMedium: TextStyle(
        fontFamily: sourceSerif4,
        fontFamilyFallback: serifFallback,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: AppColors.inkWhite,
      ),
      labelSmall: TextStyle(
        fontFamily: sourceSerif4,
        fontFamilyFallback: sansFallback,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        color: AppColors.inkWhite,
      ),
    );
  }
}
