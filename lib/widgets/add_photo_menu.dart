/// 添加照片菜单
///
/// 侦探线索墙应用中用于添加照片的底部菜单。
/// 用户从相册选取照片后创建独立的照片卡片。
library;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import 'dialogs/app_dialog_components.dart';
import 'press_scale_button.dart';

/// 添加照片菜单组件
///
/// 以底部面板形式展示，点击后启动系统图片选择器。
/// 选取照片后通过 [onPhotoSelected] 回调返回结果。
class AddPhotoMenu extends StatefulWidget {
  final VoidCallback onCancel;
  final void Function(XFile image) onPhotoSelected;

  const AddPhotoMenu({
    super.key,
    required this.onCancel,
    required this.onPhotoSelected,
  });

  @override
  State<AddPhotoMenu> createState() => _AddPhotoMenuState();
}

class _AddPhotoMenuState extends State<AddPhotoMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Animation<double> _staggeredInterval(double start, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppDragHandle(),
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.redThread.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate,
                    size: 18,
                    color: AppColors.redThread.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '添加照片',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkBlack.withValues(alpha: 0.85),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '选择一张照片，钉在线索墙上',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.inkBlack.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 选项按钮（带入场动画）
          FadeTransition(
            opacity: _staggeredInterval(0.2, 0.7),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(_staggeredInterval(0.2, 0.7)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _OptionButton(
                  icon: Icons.photo_library,
                  title: '从相册选择',
                  description: '从相册选取照片，创建独立的照片卡片',
                  onTap: () async {
                    final picker = ImagePicker();
                    final image =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      widget.onPhotoSelected(image);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// 选项按钮组件
class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _OptionButton({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScaleButton(
      scaleEnd: 0.97,
      onTap: onTap,
      builder: (context, isPressed, child) {
        return Opacity(
          opacity: onTap != null ? 1.0 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.vintageCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.sepia.withValues(alpha: isPressed ? 0.25 : 0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isPressed ? 0.12 : 0.08),
                  blurRadius: isPressed ? 8 : 6,
                  offset: Offset(0, isPressed ? 3 : 2),
                ),
                AppShadows.subtleSepia,
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.redThread.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.redThread, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkBlack.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.inkBlack.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.sepia.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
