/// 主题 Provider 模块
///
/// 管理应用的亮色/暗色主题切换，使用 Riverpod 状态管理。
/// 支持三种模式：亮色、暗色、跟随系统。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主题模式枚举
enum AppThemeMode {
  light, // 亮色模式
  dark, // 暗色模式
  system, // 跟随系统
}

/// 主题状态
class ThemeState {
  final AppThemeMode mode;
  final bool isDark;

  const ThemeState({
    this.mode = AppThemeMode.system,
    this.isDark = false,
  });

  ThemeState copyWith({
    AppThemeMode? mode,
    bool? isDark,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      isDark: isDark ?? this.isDark,
    );
  }
}

/// 主题通知器
///
/// 管理主题状态，提供切换主题的方法。
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    return const ThemeState();
  }

  /// 切换到亮色模式
  void setLight() {
    state = state.copyWith(mode: AppThemeMode.light, isDark: false);
  }

  /// 切换到暗色模式
  void setDark() {
    state = state.copyWith(mode: AppThemeMode.dark, isDark: true);
  }

  /// 切换到跟随系统模式
  void setSystem() {
    state = state.copyWith(mode: AppThemeMode.system);
    // isDark 将由系统亮度决定，需要在 UI 层更新
  }

  /// 更新系统亮度变化
  void updateSystemBrightness(Brightness brightness) {
    if (state.mode == AppThemeMode.system) {
      state = state.copyWith(isDark: brightness == Brightness.dark);
    }
  }

  /// 切换亮色/暗色模式
  void toggle() {
    if (state.isDark) {
      setLight();
    } else {
      setDark();
    }
  }

  /// 获取当前主题模式的图标
  IconData get themeIcon {
    switch (state.mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// 获取当前主题模式的文本描述
  String get themeLabel {
    switch (state.mode) {
      case AppThemeMode.light:
        return '亮色模式';
      case AppThemeMode.dark:
        return '暗色模式';
      case AppThemeMode.system:
        return '跟随系统';
    }
  }
}

/// 主题 Provider
final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
