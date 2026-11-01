/// 线索类型视觉映射
///
/// 将模型层的 [CardType] / [ConnectionType] 映射为图标与配色，
/// 使 UI 层无需重复 switch，保证卡片图钉、类型徽章和连线颜色一致。
library;

import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/connection_model.dart';
import 'app_colors.dart';

/// 卡片类型的视觉样式
extension CardTypeStyle on CardType {
  /// 类型图标
  IconData get icon => switch (this) {
        CardType.person => Icons.person_outline,
        CardType.location => Icons.place_outlined,
        CardType.event => Icons.event_note_outlined,
      };

  /// 类型强调色（用于徽章文字、图标和选中态）
  Color get color => switch (this) {
        CardType.person => AppColors.pinRed,
        CardType.location => AppColors.pinBlue,
        CardType.event => AppColors.tagOrange,
      };

  /// 图钉颜色：用金属色区分类型
  Color get pinColor => switch (this) {
        CardType.person => AppColors.pinRed,
        CardType.location => AppColors.pinBlue,
        CardType.event => AppColors.pinBrass,
      };
}

/// 一条连线的三段式颜色（主线 / 高光 / 暗部）
class ThreadPalette {
  final Color base;
  final Color light;
  final Color dark;

  const ThreadPalette({
    required this.base,
    required this.light,
    required this.dark,
  });
}

/// 关系类型的视觉样式
extension ConnectionTypeStyle on ConnectionType {
  /// 关系图标
  IconData get icon => switch (this) {
        ConnectionType.neutral => Icons.link,
        ConnectionType.ally => Icons.handshake_outlined,
        ConnectionType.enemy => Icons.flash_on_outlined,
        ConnectionType.custom => Icons.edit_outlined,
      };

  /// 关系强调色（用于选择器、标签和端点箭头）
  Color get color => palette.base;

  /// 连线三段色：中立保留经典红线，盟友为橄榄绿，敌对为近黑，自定义为灰蓝
  ThreadPalette get palette => switch (this) {
        ConnectionType.neutral => const ThreadPalette(
            base: AppColors.redThread,
            light: AppColors.redThreadLight,
            dark: AppColors.redThreadDark,
          ),
        ConnectionType.ally => const ThreadPalette(
            base: AppColors.pinGreen,
            light: AppColors.sageGreen,
            dark: Color(0xFF2F4428),
          ),
        ConnectionType.enemy => const ThreadPalette(
            base: Color(0xFF241C16),
            light: Color(0xFF5C4B3C),
            dark: Color(0xFF0D0906),
          ),
        ConnectionType.custom => const ThreadPalette(
            base: AppColors.dustyBlue,
            light: Color(0xFF7890A0),
            dark: Color(0xFF36495A),
          ),
      };
}
