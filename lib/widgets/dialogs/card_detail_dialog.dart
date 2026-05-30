/// 人物卡片详情对话框
///
/// 侦探线索墙应用中用于查看和编辑人物卡片信息的底部抽屉对话框。
/// 用户点击线索墙上的人物卡片后弹出，可以查看该人物关联的连线数量、
/// 编辑姓名/标签/备注，以及执行连线、保存、删除等操作。
///
/// 设计理念：模拟侦探翻开一张人物便签卡查看背面详细笔记的体验。
/// - 顶部显示人物姓名和关联连线数（红色徽章），一眼掌握关键信息
/// - 三个操作按钮"连线/保存/删除"对应侦探工作流中的核心动作：
///   连线 = 建立人物关系，保存 = 更新笔记，删除 = 移除线索
/// - 删除操作需要二次确认，并提示将连带删除的连线数量
/// - 使用 ConsumerStatefulWidget 以便通过 Riverpod 读写卡片和连线数据
library;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/card_model.dart';
import '../../models/connection_model.dart';
import '../../providers/card_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/photo_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_haptics.dart';
import 'app_dialog_components.dart';

/// 人物卡片详情对话框
///
/// 以底部抽屉形式展示，包含以下功能区域：
/// - 标题栏：人物姓名 + 关联连线数量徽章
/// - 编辑区：姓名、标签、备注三个输入框
/// - 操作栏：连线、保存、删除三个按钮
///
/// [onStartConnecting] 回调用于启动连线模式——关闭当前对话框后
/// 通知父组件进入"从该卡片出发画线"的交互状态。
class CardDetailDialog extends ConsumerStatefulWidget {
  /// 要查看/编辑的人物卡片数据
  final ClueCard card;

  /// 启动连线模式的回调，关闭对话框后触发
  final VoidCallback onStartConnecting;

  const CardDetailDialog({
    super.key,
    required this.card,
    required this.onStartConnecting,
  });

  @override
  ConsumerState<CardDetailDialog> createState() => _CardDetailDialogState();
}

class _CardDetailDialogState extends ConsumerState<CardDetailDialog>
    with SingleTickerProviderStateMixin, DialogEntranceMixin {
  /// 姓名编辑控制器，初始化为当前卡片姓名
  late final TextEditingController _nameController;

  /// 备注编辑控制器，初始化为当前卡片备注（可能为空）
  late final TextEditingController _descController;

  /// 标签编辑控制器，初始化为当前卡片标签的逗号分隔字符串
  late final TextEditingController _tagsController;

  /// 是否正在保存中
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card.name);
    _descController =
        TextEditingController(text: widget.card.description ?? '');
    _tagsController = TextEditingController(text: widget.card.tags.join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  /// 获取当前卡片关联的所有连线
  ///
  /// 从 Riverpod 的连线列表中筛选出 fromCardId 或 toCardId
  /// 等于当前卡片 ID 的连线。用于：
  /// - 在标题栏显示连线数量徽章
  /// - 在删除确认对话框中提示将连带删除的连线数
  /// - 在关联预览区显示关联的卡片/照片
  List<Connection> get _cardConnections {
    final connections = ref.read(connectionListProvider).value ?? [];
    return connections
        .where((c) =>
            c.fromCardId == widget.card.id || c.toCardId == widget.card.id)
        .toList();
  }

  /// 获取与当前卡片关联的卡片/照片名称列表
  ///
  /// 遍历所有关联连线，提取对端的卡片或照片名称，
  /// 用于在关联预览区显示。
  List<_ConnectedItem> _getConnectedItems() {
    final connections = _cardConnections;
    if (connections.isEmpty) return [];

    final cards = ref.read(cardListProvider).value ?? [];
    final photos = ref.read(photoListProvider).value ?? [];
    final items = <_ConnectedItem>[];

    for (final conn in connections) {
      if (conn.fromCardId == widget.card.id) {
        // 当前卡片是起点，取终点
        if (conn.toCardId != null) {
          final card = cards.firstWhereOrNull((c) => c.id == conn.toCardId);
          if (card != null) {
            items.add(_ConnectedItem(
              name: card.name,
              icon: Icons.person,
              label: conn.label,
            ));
          }
        } else if (conn.toPhotoId != null) {
          final photo = photos.firstWhereOrNull((p) => p.id == conn.toPhotoId);
          items.add(_ConnectedItem(
            name: photo?.caption ?? '照片',
            icon: Icons.photo,
            label: conn.label,
          ));
        }
      } else if (conn.toCardId == widget.card.id) {
        // 当前卡片是终点，取起点
        if (conn.fromCardId != null) {
          final card = cards.firstWhereOrNull((c) => c.id == conn.fromCardId);
          if (card != null) {
            items.add(_ConnectedItem(
              name: card.name,
              icon: Icons.person,
              label: conn.label,
            ));
          }
        } else if (conn.fromPhotoId != null) {
          final photo =
              photos.firstWhereOrNull((p) => p.id == conn.fromPhotoId);
          items.add(_ConnectedItem(
            name: photo?.caption ?? '照片',
            icon: Icons.photo,
            label: conn.label,
          ));
        }
      }
    }
    return items;
  }

  /// 保存编辑后的卡片数据
  ///
  /// 执行流程：
  /// 1. 校验姓名是否为空
  /// 2. 触发轻量触觉反馈
  /// 3. 解析标签字符串
  /// 4. 通过 Riverpod provider 更新卡片数据
  /// 5. 关闭对话框
  Future<void> _save() async {
    final name = _nameController.text.trim();
    // 姓名为必填字段
    if (name.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    AppHaptics.light();

    // 解析逗号分隔的标签
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final descText = _descController.text.trim();
    // 使用 copyWith 更新卡片，空备注通过 clearDescription 标记清除
    await ref.read(cardListProvider.notifier).updateCard(
          widget.card.copyWith(
            name: name,
            tags: tags,
            description: descText.isEmpty ? null : descText,
            clearDescription: descText.isEmpty,
            updatedAt: DateTime.now(),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  /// 删除当前卡片
  ///
  /// 弹出二次确认对话框，提示用户删除卡片将连带删除关联的连线。
  /// 确认后触发重度触觉反馈（模拟撕毁/拔除的物理感），
  /// 然后通过 provider 删除卡片数据并关闭所有对话框。
  void _delete() {
    final cardConnections = _cardConnections;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppConfirmSheet(
        title: '确认删除',
        message: '将同时删除 ${cardConnections.length} 条连线',
        onConfirm: () async {
          AppHaptics.cardDeleted();
          await ref.read(cardListProvider.notifier).deleteCard(widget.card.id!);
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 获取关联连线数，用于标题栏徽章显示
    final cardConnections = _cardConnections;

    return AppDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 拖拽手柄
          const AppDragHandle(),
          // 标题栏：人物姓名 + 连线数量徽章
          AppDialogTitle(
            icon: Icons.person,
            title: widget.card.name,
            iconBgColor: AppColors.agedPaper.withValues(alpha: 0.5),
            iconColor: AppColors.sepia.withValues(alpha: 0.6),
            trailing: cardConnections.isNotEmpty
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.redThread.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.redThread.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link,
                            size: 12,
                            color: AppColors.redThread.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          '${cardConnections.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.redThread.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          const SizedBox(height: DialogConstants.sectionGapMedium),
          // 输入框区域（带入场动画）
          FadeTransition(
            opacity: staggeredInterval(0.1, 0.55),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 姓名编辑框
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DialogConstants.horizontalPadding),
                  child: AppTextField(
                    controller: _nameController,
                    hint: '姓名',
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: DialogConstants.sectionGapSmall),
                // 标签编辑框
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DialogConstants.horizontalPadding),
                  child: AppTextField(
                    controller: _tagsController,
                    hint: '标签（逗号分隔）',
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: DialogConstants.sectionGapSmall),
                // 备注编辑框
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DialogConstants.horizontalPadding),
                  child: AppTextField(
                      controller: _descController, hint: '备注', maxLines: 2),
                ),
              ],
            ),
          ),
          // 关联预览区：显示与此卡片关联的卡片/照片
          if (cardConnections.isNotEmpty) ...[
            const SizedBox(height: 4),
            FadeTransition(
              opacity: staggeredInterval(0.3, 0.7),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DialogConstants.horizontalPadding),
                child: _buildConnectedPreview(),
              ),
            ),
          ],
          const SizedBox(height: DialogConstants.sectionGapLarge),
          // 操作按钮栏：连线 / 保存 / 删除（带入场动画）
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
                        label: '连线',
                        color: AppColors.redThread.withValues(alpha: 0.88),
                        filled: false,
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onStartConnecting();
                        },
                      ),
                    ),
                    const SizedBox(width: DialogConstants.buttonGap),
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

  /// 构建关联预览区
  ///
  /// 显示与此卡片关联的卡片/照片名称，以紧凑的 chip 形式排列。
  /// 每个 chip 显示对端图标 + 名称 + 关系标签（如有）。
  Widget _buildConnectedPreview() {
    final items = _getConnectedItems();
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.agedPaper.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.sepia.withValues(alpha: 0.1),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.link,
                  size: 12, color: AppColors.sepia.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                '关联',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.sepia.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.agedPaper.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: AppColors.sepia.withValues(alpha: 0.12),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon,
                        size: 11,
                        color: AppColors.sepia.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.inkBlack.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.label != null && item.label!.isNotEmpty) ...[
                      Text(
                        ' · ',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.sepia.withValues(alpha: 0.35),
                        ),
                      ),
                      Text(
                        item.label!,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.redThread.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 关联项数据
class _ConnectedItem {
  final String name;
  final IconData icon;
  final String? label;

  const _ConnectedItem({
    required this.name,
    required this.icon,
    this.label,
  });
}
