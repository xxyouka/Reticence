/// 应用主题配置 —— 侦探软木板美学的 Material 化
///
/// 本文件将 [AppColors] 和 [AppTypography] 中定义的视觉元素
/// 转化为 Flutter 的 [ThemeData] 配置，使侦探软木板的美学风格
/// 能够一致地应用到所有 Material 组件上。
///
/// 设计原则：
/// - 每个组件的主题都应体现"旧纸+软木板"的物理质感
/// - 圆角保持极小（2-6px），模拟真实纸张的轻微卷曲而非数字化的圆润
/// - 阴影使用暖色调而非纯黑，模拟暖光照射下的自然投影
/// - 边框使用低透明度的墨水色/棕褐色，模拟纸张的毛边和磨损
/// - 亮色与暗色模式共享同一设计语言，仅调整明暗关系
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// 自定义页面过渡构建器 —— 淡入滑动效果
///
/// 替代默认的 MaterialPageRoute 水平滑动，
/// 使用从底部淡入+微滑的过渡效果，与底部抽屉的视觉语言一致。
class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

class AppTheme {
  /// 亮色主题——模拟白天的侦探办公室
  ///
  /// 软木板背景在自然光下呈现中等的棕色调，
  /// 纸张卡片保持泛黄的旧纸色，墨水文字清晰可读。
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, // 启用 Material 3 设计规范
      brightness: Brightness.light,
      // 色彩方案：以墨水黑为主色，红线为强调色
      // primary = 墨水黑：主要交互元素（按钮、开关等）使用墨水色
      // secondary = 红线色：次要强调和选中状态使用红线色
      // surface = 软木板色：整个页面背景模拟软木板
      colorScheme: const ColorScheme.light(
        primary: AppColors.inkBlack,
        onPrimary: AppColors.paperWhite,
        secondary: AppColors.redThread,
        onSecondary: AppColors.paperWhite,
        surface: AppColors.corkBoard,
        onSurface: AppColors.inkBlack,
        error: AppColors.redThread, // 错误状态也使用红线色，保持视觉一致性
        onError: AppColors.paperWhite,
      ),
      scaffoldBackgroundColor: AppColors.corkBoard, // 页面底色为软木板
      textTheme: AppTypography.lightTextTheme(),
      // 卡片主题：模拟钉在软木板上的旧纸卡片
      // - 老旧纸张色背景，微弱阴影模拟翘起的纸角
      // - 极小圆角（3px）模拟纸张的轻微卷曲
      // - 低透明度墨水色边框模拟纸张毛边
      cardTheme: CardThemeData(
        color: AppColors.agedPaper,
        elevation: 2, // 微弱阴影，模拟纸张微微翘起
        shadowColor: AppColors.shadowColor, // 暖色阴影，非纯黑
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3), // 极小圆角，模拟纸张自然卷曲
          side: BorderSide(
            color: AppColors.inkBlack.withValues(alpha: 0.1), // 极淡的墨水色边框
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      // 底部弹窗主题：从底部滑出的旧纸面板
      // - 无阴影（elevation: 0），与软木板背景自然融合
      // - 顶部微圆角，模拟纸张从下方露出
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.agedPaper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        ),
        elevation: 0, // 无阴影，让弹窗与背景自然融合
      ),
      // 标签主题：线索分类标签
      // - 旧纸色底，选中时叠加半透明蓝色
      // - 极小圆角（2px）和细边框，模拟手撕标签纸
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.agedPaper,
        selectedColor: AppColors.tagBlue.withValues(alpha: 0.3), // 选中时半透明蓝色
        labelStyle: AppTypography.lightTextTheme().labelSmall,
        side: BorderSide(
          color: AppColors.inkBlack.withValues(alpha: 0.12), // 极淡边框
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2), // 极小圆角，模拟标签纸
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      // 对话框主题：弹出式旧纸面板
      // - 比卡片稍高的阴影（elevation: 4），强调层级
      // - 棕褐色半透明边框，模拟旧纸的磨损边缘
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.agedPaper,
        elevation: 4, // 比卡片更高的阴影，强调对话框层级
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: BorderSide(
            color: AppColors.sepia.withValues(alpha: 0.2), // 棕褐色边框
            width: 1,
          ),
        ),
        titleTextStyle: AppTypography.lightTextTheme().headlineMedium,
      ),
      // 应用栏主题：模拟软木板顶部的深色画框
      // - 半透明深棕色背景，让底层软木板纹理若隐若现
      // - 浅色前景文字，确保在深色背景上可读
      // - 无阴影，与软木板自然衔接
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.corkFrame.withValues(alpha: 0.85), // 半透明画框色
        foregroundColor: AppColors.agedPaper, // 浅色文字/图标
        elevation: 0, // 无阴影，与背景融合
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // 透明状态栏
          statusBarIconBrightness: Brightness.light, // 亮色状态栏图标
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.lightTextTheme().headlineMedium?.copyWith(
              color: AppColors.agedPaper,
            ),
      ),
      // 浮动操作按钮主题：红线色的醒目按钮
      // - 红线色背景，呼应侦探串联线索的红线符号
      // - 旧纸色图标，与卡片纸张色一致
      // - 适中阴影（elevation: 3），模拟图钉钉在板上的凸起感
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.redThread, // 红线色——核心操作按钮
        foregroundColor: AppColors.agedPaper,
        elevation: 3, // 适中阴影，模拟图钉凸起
      ),
      // 分隔线主题：极淡的棕褐色线条
      // 模拟旧纸上轻微的折痕或磨损痕迹
      dividerTheme: DividerThemeData(
        color: AppColors.sepia.withValues(alpha: 0.15), // 极淡棕褐色
        thickness: 1,
      ),
      // 页面过渡主题：淡入+微滑效果，替代默认水平滑动
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }

  /// 暗色主题——模拟夜间的侦探办公室
  ///
  /// 整体色调更暗更沉，软木板接近画框的深色，
  /// 纸张变为深褐色，文字变为浅暖色。
  /// 红线提亮以确保在深色背景上仍然醒目，
  /// 保持"昏暗灯光下翻阅线索"的氛围感。
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // 暗色色彩方案：明暗关系反转但保持暖色调
      // primary = 浅墨水色（inkWhite）：在深色背景上提供可读文字
      // secondary = 暗色模式红线：提亮的红色保证可见性
      // surface = 暗色软木板：接近画框的深棕色
      colorScheme: const ColorScheme.dark(
        primary: AppColors.inkWhite,
        onPrimary: AppColors.inkBlack,
        secondary: AppColors.redThreadDarkMode,
        onSecondary: AppColors.inkBlack,
        surface: AppColors.corkBoardDarkMode,
        onSurface: AppColors.inkWhite,
        error: AppColors.redThreadDarkMode,
        onError: AppColors.inkBlack,
      ),
      scaffoldBackgroundColor: AppColors.corkBoardDarkMode, // 深色软木板底色
      textTheme: AppTypography.darkTextTheme(),
      // 暗色卡片主题：深褐色纸张替代泛黄白纸
      // 边框使用极低透明度的浅色，模拟深色纸张的边缘反光
      cardTheme: CardThemeData(
        color: AppColors.paperWhiteDark, // 深褐色纸张
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: BorderSide(
            color: AppColors.inkWhite.withValues(alpha: 0.08), // 极淡浅色边框
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      // 暗色底部弹窗：半透明深褐色，让底层内容若隐若现
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            AppColors.paperWhiteDark.withValues(alpha: 0.8), // 半透明深褐色
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
        ),
        elevation: 0,
      ),
      // 暗色标签：深褐色底，选中时同样叠加半透明蓝色
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paperWhiteDark,
        selectedColor: AppColors.tagBlue.withValues(alpha: 0.3),
        labelStyle: AppTypography.darkTextTheme().labelSmall,
        side: BorderSide(
          color: AppColors.inkWhite.withValues(alpha: 0.1), // 浅色边框
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      // 暗色对话框：深褐色面板，边框更淡
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paperWhiteDark,
        elevation: 4,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: BorderSide(
            color: AppColors.inkWhite.withValues(alpha: 0.06), // 更淡的浅色边框
            width: 1,
          ),
        ),
        titleTextStyle: AppTypography.darkTextTheme().headlineMedium,
      ),
      // 暗色应用栏：更深更沉的软木色
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.corkBoardDarkMode.withValues(alpha: 0.9),
        foregroundColor: AppColors.inkWhite,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.darkTextTheme().headlineMedium,
      ),
      // 暗色浮动按钮：提亮的红线色
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.redThreadDarkMode, // 提亮的红线色
        foregroundColor: AppColors.inkWhite,
        elevation: 3,
      ),
      // 暗色分隔线：极淡的浅色线条
      dividerTheme: DividerThemeData(
        color: AppColors.inkWhite.withValues(alpha: 0.06), // 极淡浅色
        thickness: 1,
      ),
      // 暗色页面过渡：与亮色主题一致
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: _FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }
}
