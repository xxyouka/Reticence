/// 照片风格选择器 —— 让用户选择拍立得风格
///
/// 提供两种风格选项：
/// - 经典拍立得（polaroid）：白色边框，干净利落
/// - 复古拍立得（vintage）：泛黄旧纸，岁月质感
library;

import 'package:flutter/material.dart';

import '../../models/photo_card_model.dart';
import '../../theme/app_colors.dart';
import 'app_dialog_components.dart';
import '../../screens/style_option.dart';

/// 显示照片风格选择底部弹窗
///
/// [onStyleSelected] 在用户选择风格后回调。
void showPhotoStylePicker(
  BuildContext context, {
  required void Function(PhotoStyle) onStyleSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AppDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppDragHandle(),
          // 标题
          const AppDialogTitle(
            icon: Icons.style,
            title: '照片风格',
            iconColor: AppColors.inkBlack,
          ),
          const SizedBox(height: DialogConstants.sectionGapLarge),
          // 风格选项
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: DialogConstants.horizontalPadding),
            child: Row(
              children: [
                Expanded(
                  child: StyleOption(
                    label: '经典拍立得',
                    description: '白色边框，干净利落',
                    borderColor: Colors.white,
                    bgColor: Colors.white,
                    onTap: () {
                      Navigator.pop(ctx);
                      onStyleSelected(PhotoStyle.polaroid);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StyleOption(
                    label: '复古拍立得',
                    description: '泛黄旧纸，岁月质感',
                    borderColor: AppColors.agedPaper,
                    bgColor: AppColors.agedPaper,
                    onTap: () {
                      Navigator.pop(ctx);
                      onStyleSelected(PhotoStyle.vintage);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DialogConstants.sectionGapLarge),
        ],
      ),
    ),
  );
}
