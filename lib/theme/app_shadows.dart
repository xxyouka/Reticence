/// 应用阴影体系 —— 统一的 BoxShadow 常量
///
/// 提供侦探线索墙应用中高频复用的阴影配置，避免各文件重复定义。
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  /// 淡黑色底层微阴影 —— 模拟纸张轻微浮起
  ///
  /// 用于对话框选项、输入框等轻量级组件的底层阴影。
  static const subtleBlack = BoxShadow(
    color: Colors.black26,
    blurRadius: 3,
    offset: Offset(0, 1),
  );

  /// 淡棕褐色底层微阴影 —— 模拟旧纸张的温润浮起感
  ///
  /// 用于工具栏按钮、选项卡片等需要暖色调阴影的组件。
  static final subtleSepia = BoxShadow(
    color: AppColors.sepia.withValues(alpha: 0.05),
    blurRadius: 3,
    offset: const Offset(0, 1),
  );

  /// 卡片拖拽阴影 —— 模拟卡片被抬起时的深色投影
  ///
  /// 用于线索卡片和照片卡片在拖拽状态下的阴影效果。
  static final cardDrag = BoxShadow(
    color: Colors.black.withValues(alpha: 0.35),
    offset: const Offset(0, 6),
    blurRadius: 20,
    spreadRadius: 2,
  );

  /// 红线发光阴影 —— 连线目标的红色脉冲光晕
  ///
  /// 用于连线模式下目标卡片的图钉脉冲动画。
  static const redThreadGlow = BoxShadow(
    color: AppColors.redThread,
    offset: Offset(0, 3),
    blurRadius: 14,
    spreadRadius: 3,
  );
}
