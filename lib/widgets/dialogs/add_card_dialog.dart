/// 添加线索卡片对话框
///
/// 侦探线索墙应用的核心交互组件之一。当用户在画布空白处长按或点击添加按钮时，
/// 弹出此底部抽屉式对话框，用于录入新线索的类型和基本信息。
///
/// 设计理念：模拟侦探在软木板上钉上一张新的线索便签卡的过程。
/// - 类型选择器让人物、地点、事件在创建时就拥有身份
/// - 提交按钮文案"钉上去"呼应图钉钉入软木板的动作隐喻
/// - 每张卡片创建时会自动生成随机旋转角度和偏移量，模拟手工钉卡片时的
///   自然不规则感，避免所有卡片整齐排列的机械感
/// - 使用 ConsumerStatefulWidget 以便通过 Riverpod 访问卡片数据提供者
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/card_model.dart';
import '../../providers/card_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/clue_type_style.dart';
import '../../theme/wall_constants.dart';
import '../../utils/app_haptics.dart';
import 'app_dialog_components.dart';
import 'type_selectors.dart';

/// 添加人物卡片对话框
///
/// 以底部抽屉形式展示，包含姓名、标签（逗号分隔）和备注三个输入字段。
/// 创建成功后通过 [onCardAdded] 回调通知父组件，以便执行动画等后续操作。
///
/// 关键设计点：
/// - [canvasPosition] 记录当前画布视口中心，新卡片将以此为中心放置
/// - 旋转角度在 [initState] 中一次性生成，确保同一张卡片的旋转值在
///   整个生命周期内保持一致
class AddCardDialog extends ConsumerStatefulWidget {
  /// 当前画布视口中心位置，作为新卡片的中心坐标
  final Offset canvasPosition;

  /// 卡片创建成功后的回调，参数为新创建的 [ClueCard] 对象
  final void Function(ClueCard) onCardAdded;

  const AddCardDialog({
    super.key,
    required this.canvasPosition,
    required this.onCardAdded,
  });

  @override
  ConsumerState<AddCardDialog> createState() => _AddCardDialogState();
}

class _AddCardDialogState extends ConsumerState<AddCardDialog>
    with SingleTickerProviderStateMixin, DialogEntranceMixin {
  /// 姓名输入控制器
  final _nameController = TextEditingController();

  /// 备注输入控制器
  final _descController = TextEditingController();

  /// 标签输入控制器（用户以逗号分隔输入多个标签）
  final _tagsController = TextEditingController();

  /// 姓名输入框的焦点节点，用于控制自动聚焦
  final _nameFocus = FocusNode();

  /// 共享的随机数生成器，用于生成卡片旋转角度和位置偏移
  static final _random = Random();

  /// 卡片的随机旋转角度（弧度制），在 initState 中初始化
  late final double _rotation;

  /// 是否正在提交中
  bool _isLoading = false;

  /// 当前选择的线索类型
  CardType _selectedType = CardType.person;

  @override
  void initState() {
    super.initState();
    _rotation = (_random.nextDouble() - 0.5) *
        WallConstants.maxRotationDegrees *
        pi /
        180;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }


  /// 提交新卡片数据
  ///
  /// 执行流程：
  /// 1. 校验姓名是否为空（姓名为必填项）
  /// 2. 触发中等强度触觉反馈，模拟"钉入"的物理感
  /// 3. 解析标签字符串：按逗号分割、去除空白、过滤空标签
  /// 4. 在画布点击位置基础上叠加随机偏移，使卡片不会完全重叠在点击点
  /// 5. 通过 Riverpod provider 持久化卡片数据
  /// 6. 创建成功后关闭对话框并触发回调
  Future<void> _submit() async {
    final name = _nameController.text.trim();
    // 姓名为必填字段，为空时不执行任何操作
    if (name.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    // 触觉反馈：双拍节奏，模拟图钉钉入软木板的手感
    AppHaptics.cardAdded();

    // 解析逗号分隔的标签字符串，去除首尾空白并过滤空值
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // 构建卡片模型并通过 provider 持久化
    final newCard = await ref.read(cardListProvider.notifier).addCard(
          ClueCard(
            name: name,
            cardType: _selectedType,
            tags: tags,
            // 备注为可选项，空字符串存储为 null
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            x: widget.canvasPosition.dx - WallConstants.cardWidth / 2,
            y: widget.canvasPosition.dy - WallConstants.cardHeight / 2,
            width: WallConstants.cardWidth,
            height: WallConstants.cardHeight,
            // 使用 initState 中生成的随机旋转角度
            rotation: _rotation,
          ),
        );

    // 确保组件仍然挂载且卡片创建成功后再执行导航和回调
    if (mounted && newCard != null) {
      Navigator.of(context).pop();
      widget.onCardAdded(newCard);
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用统一的对话框外壳组件，保证所有对话框视觉风格一致
    return AppDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部拖拽手柄，视觉提示用户可以下拉关闭
          const AppDragHandle(),
          // 对话框标题
          AppDialogTitle(
            icon: _selectedType.icon,
            title: '新${_selectedType.label}',
            iconColor: _selectedType.color.withValues(alpha: 0.75),
            iconBgColor: _selectedType.color.withValues(alpha: 0.1),
          ),
          const SizedBox(height: DialogConstants.sectionGapMedium),
          // 输入框区域（带入场动画）
          FadeTransition(
            opacity: staggeredInterval(0.1, 0.55),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 线索类型选择器
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DialogConstants.horizontalPadding),
                  child: ClueTypeSelector(
                    selected: _selectedType,
                    onChanged: (type) {
                      setState(() => _selectedType = type);
                    },
                  ),
                ),
                const SizedBox(height: DialogConstants.sectionGapSmall),
                // 姓名输入框
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DialogConstants.horizontalPadding),
                  child: AppTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    hint: '姓名或名称',
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: DialogConstants.sectionGapSmall),
                // 标签输入框
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DialogConstants.horizontalPadding),
                  child: AppTextField(
                    controller: _tagsController,
                    hint: '标签（逗号分隔）',
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(height: DialogConstants.sectionGapSmall),
                // 备注输入框
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DialogConstants.horizontalPadding),
                  child: AppTextField(
                    controller: _descController,
                    hint: '备注（可选）',
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _submit,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // 提交按钮（带入场动画）
          FadeTransition(
            opacity: staggeredInterval(0.5, 1.0),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(staggeredInterval(0.5, 1.0)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: DialogConstants.horizontalPadding),
                child: AppActionButton(
                  label: '钉上去',
                  color: AppColors.redThread.withValues(alpha: 0.88),
                  filled: true,
                  onTap: _submit,
                  isLoading: _isLoading,
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
