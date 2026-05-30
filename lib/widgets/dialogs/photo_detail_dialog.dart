/// 照片详情对话框
///
/// 侦探线索墙应用中用于查看和编辑照片信息的底部抽屉对话框。
/// 用户双击线索墙上的照片后弹出，可以编辑说明文字、调整缩放比例、删除照片。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/photo_card_model.dart';
import '../../providers/connection_provider.dart';
import '../../providers/photo_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_haptics.dart';
import 'app_dialog_components.dart';

/// 照片详情对话框
///
/// 以底部抽屉形式展示，包含以下功能区域：
/// - 标题栏：照片类型标签
/// - 编辑区：说明文字输入框
/// - 缩放区：缩放滑块 + 百分比显示 + 重置按钮
/// - 操作栏：保存、删除按钮
class PhotoDetailDialog extends ConsumerStatefulWidget {
  /// 要查看/编辑的照片数据
  final PhotoCard photo;

  const PhotoDetailDialog({
    super.key,
    required this.photo,
  });

  @override
  ConsumerState<PhotoDetailDialog> createState() => _PhotoDetailDialogState();
}

class _PhotoDetailDialogState extends ConsumerState<PhotoDetailDialog>
    with SingleTickerProviderStateMixin, DialogEntranceMixin {
  late final TextEditingController _captionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _captionController =
        TextEditingController(text: widget.photo.caption ?? '');
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    AppHaptics.light();

    final captionText = _captionController.text.trim();
    await ref.read(photoListProvider.notifier).updatePhoto(
          widget.photo.copyWith(
            caption: captionText.isEmpty ? null : captionText,
            clearCaption: captionText.isEmpty,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  void _delete() {
    final connections = ref.read(connectionListProvider).value ?? [];
    final photoId = widget.photo.id;
    final connectionCount = photoId == null
        ? 0
        : connections
            .where((c) => c.fromPhotoId == photoId || c.toPhotoId == photoId)
            .length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppConfirmSheet(
        title: '确认删除',
        message: connectionCount > 0
            ? '将同时删除 $connectionCount 条连线'
            : '将永久删除这张照片',
        onConfirm: () async {
          AppHaptics.cardDeleted();
          await ref.read(photoListProvider.notifier).deletePhoto(widget.photo.id!);
          if (mounted) Navigator.of(context).pop();
        },
      ),
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
          // 标题栏
          AppDialogTitle(
            icon: Icons.photo,
            title: '照片详情',
            iconColor: AppColors.sepia.withValues(alpha: 0.7),
            iconBgColor: AppColors.sepia.withValues(alpha: 0.08),
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: widget.photo.photoStyle == PhotoStyle.vintage
                    ? AppColors.agedPaper.withValues(alpha: 0.6)
                    : AppColors.paperWhite.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.sepia.withValues(alpha: 0.15),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.photo.photoStyle == PhotoStyle.vintage
                        ? Icons.auto_awesome
                        : Icons.photo_camera,
                    size: 14,
                    color: AppColors.sepia.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.photo.photoStyle == PhotoStyle.vintage
                        ? '复古拍立得'
                        : '经典拍立得',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.sepia.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 照片预览（带入场动画）
          FadeTransition(
            opacity: staggeredInterval(0.1, 0.5),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(staggeredInterval(0.1, 0.5)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DialogConstants.horizontalPadding),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.warmGray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.sepia.withValues(alpha: 0.1),
                      width: 0.8,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: File(widget.photo.imagePath).isAbsolute
                      ? Image.file(
                          File(widget.photo.imagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: AppColors.warmGray.withValues(alpha: 0.4),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: AppColors.warmGray.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 说明文字输入框（带入场动画）
          FadeTransition(
            opacity: staggeredInterval(0.3, 0.7),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DialogConstants.horizontalPadding),
              child: AppTextField(
                controller: _captionController,
                hint: '添加说明文字...',
                autofocus: true,
              ),
            ),
          ),
          const SizedBox(height: DialogConstants.sectionGapLarge),
          // 操作按钮栏：保存 / 删除（带入场动画）
          FadeTransition(
            opacity: staggeredInterval(0.5, 1.0),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(staggeredInterval(0.5, 1.0)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DialogConstants.horizontalPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: AppActionButton(
                        label: '保存',
                        color: AppColors.sageGreen,
                        filled: true,
                        onTap: _save,
                        isLoading: _isLoading,
                      ),
                    ),
                    const SizedBox(width: DialogConstants.buttonGap),
                    Expanded(
                      child: AppActionButton(
                        label: '删除',
                        color: AppColors.redThread.withValues(alpha: 0.88),
                        filled: false,
                        onTap: _delete,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: DialogConstants.bottomPadding),
        ],
      ),
    );
  }

}
