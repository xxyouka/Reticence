/// 关系连线详情对话框
///
/// 用户点击线索墙上的连线后弹出，可以查看关系两端、编辑关系描述、保存或删除连线。
library;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/card_model.dart';
import '../../models/connection_model.dart';
import '../../models/photo_card_model.dart';
import '../../providers/card_provider.dart';
import '../../providers/commands/connection_commands.dart';
import '../../providers/connection_provider.dart';
import '../../providers/photo_provider.dart';
import '../../providers/undo_redo_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_haptics.dart';
import 'app_dialog_components.dart';

/// 关系连线详情对话框
///
/// 以底部抽屉形式展示，包含：标题、端点展示、关系描述输入、保存/删除。
class ConnectionDetailDialog extends ConsumerStatefulWidget {
  /// 要查看/编辑的关系连线数据
  final Connection connection;

  const ConnectionDetailDialog({
    super.key,
    required this.connection,
  });

  @override
  ConsumerState<ConnectionDetailDialog> createState() =>
      _ConnectionDetailDialogState();
}

class _ConnectionDetailDialogState
    extends ConsumerState<ConnectionDetailDialog>
    with SingleTickerProviderStateMixin, DialogEntranceMixin {
  /// 预设关系类型标签
  static const _presetLabels = ['朋友', '家人', '同事', '恋人', '同学', '其他'];

  /// 关系描述编辑控制器，初始化为当前连线的标签
  late final TextEditingController _labelController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _labelController =
        TextEditingController(text: widget.connection.label ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  /// 根据卡片 ID 查找对应的卡片对象
  ClueCard? _findCard(int? cardId) {
    if (cardId == null) return null;
    final cards = ref.read(cardListProvider).value ?? [];
    return cards.firstWhereOrNull((c) => c.id == cardId);
  }

  /// 根据照片 ID 查找对应的照片对象
  PhotoCard? _findPhoto(int? photoId) {
    if (photoId == null) return null;
    final photos = ref.read(photoListProvider).value ?? [];
    return photos.firstWhereOrNull((p) => p.id == photoId);
  }

  /// 构建端点芯片组件
  ///
  /// 卡片端点：人物图标 + 卡片名称
  /// 照片端点：照片图标 + 照片标题（或"照片"）
  Widget _endpointChip({ClueCard? card, PhotoCard? photo}) {
    final isCard = card != null;
    final name = isCard ? card.name : (photo?.caption ?? '照片');
    final icon = isCard ? Icons.person : Icons.photo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.agedPaper.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.sepia.withValues(alpha: 0.12),
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
          Icon(icon,
              size: 14, color: AppColors.sepia.withValues(alpha: 0.65)),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.inkBlack.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 保存编辑后的连线数据
  Future<void> _save() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    AppHaptics.light();
    final labelText = _labelController.text.trim();
    final updated = widget.connection.copyWith(
      label: labelText.isEmpty ? null : labelText,
      clearLabel: labelText.isEmpty,
    );
    await ref.read(undoRedoProvider.notifier).executeCommand(
          UpdateConnectionCommand(
            ref.read(connectionListProvider.notifier),
            widget.connection,
            updated,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  /// 删除当前连线
  ///
  /// 弹出确认对话框，确认后删除连线并关闭对话框。
  void _delete() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppConfirmSheet(
        title: '确认删除',
        message: '删除后关系描述将丢失',
        onConfirm: () async {
          AppHaptics.disconnect();
          await ref.read(undoRedoProvider.notifier).executeCommand(
                DeleteConnectionCommand(
                  ref.read(connectionListProvider.notifier),
                  widget.connection,
                ),
              );
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 查找连线两端的卡片或照片
    final fromCard = _findCard(widget.connection.fromCardId);
    final toCard = _findCard(widget.connection.toCardId);
    final fromPhoto = _findPhoto(widget.connection.fromPhotoId);
    final toPhoto = _findPhoto(widget.connection.toPhotoId);

    return AppDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 拖拽手柄
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
                    Icons.timeline,
                    size: 18,
                    color: AppColors.redThread.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '关系详情',
                  style: TextStyle(
                    color: AppColors.inkBlack.withValues(alpha: 0.85),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 人物关系展示区：起始人物 → 目标人物（带入场动画）
          FadeTransition(
            opacity: staggeredInterval(0.1, 0.5),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(staggeredInterval(0.1, 0.5)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.agedPaper.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.sepia.withValues(alpha: 0.1),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 起始端点
                      if (fromCard != null)
                        _endpointChip(card: fromCard)
                      else if (fromPhoto != null)
                        _endpointChip(photo: fromPhoto),
                      // 红色箭头
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.arrow_forward,
                            size: 14,
                            color: AppColors.redThread.withValues(alpha: 0.6)),
                      ),
                      // 目标端点
                      if (toCard != null)
                        _endpointChip(card: toCard)
                      else if (toPhoto != null)
                        _endpointChip(photo: toPhoto),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // 预设关系类型标签（带入场动画）
          FadeTransition(
            opacity: staggeredInterval(0.25, 0.7),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(staggeredInterval(0.25, 0.7)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: _presetLabels.map((label) {
                    final isSelected = _labelController.text == label;
                    return _PresetLabelChip(
                      label: label,
                      isSelected: isSelected,
                      onTap: () {
                        AppHaptics.selection();
                        setState(() {
                          _labelController.text = isSelected ? '' : label;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 关系描述输入框（带入场动画）
          FadeTransition(
            opacity: staggeredInterval(0.4, 0.8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppTextField(
                controller: _labelController,
                hint: '关系描述',
                autofocus: true,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 操作按钮栏：保存 / 删除（带入场动画）
          FadeTransition(
            opacity: staggeredInterval(0.55, 1.0),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(staggeredInterval(0.55, 1.0)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    const SizedBox(width: 8),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// 预设关系标签芯片 —— 带按压缩放动画
class _PresetLabelChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetLabelChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PresetLabelChip> createState() => _PresetLabelChipState();
}

class _PresetLabelChipState extends State<_PresetLabelChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.sepia.withValues(alpha: 0.18)
                : AppColors.agedPaper.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.sepia.withValues(alpha: 0.55)
                  : AppColors.sepia.withValues(alpha: 0.18),
              width: widget.isSelected ? 1.3 : 0.8,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.sepia.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  widget.isSelected ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.inkBlack
                  .withValues(alpha: widget.isSelected ? 0.85 : 0.55),
            ),
          ),
        ),
      ),
    );
  }
}
