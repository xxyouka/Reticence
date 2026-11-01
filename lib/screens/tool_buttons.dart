import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/press_scale_button.dart';

/// 右下角工具按钮组
///
/// 包含两个元素（从上到下）：
/// - 适应屏幕按钮：缩放画布以显示所有卡片
/// - 展开式 FAB：点击 "+" 展开"新关系"和"新图片"两个子按钮
class ToolButtons extends StatefulWidget {
  final VoidCallback onAddCard;
  final VoidCallback onAddPhoto;

  const ToolButtons({
    super.key,
    required this.onAddCard,
    required this.onAddPhoto,
  });

  @override
  State<ToolButtons> createState() => ToolButtonsState();
}

/// 公开 State 类型，允许外部调用 [collapse] 收起展开菜单
class ToolButtonsState extends State<ToolButtons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  // 预创建子按钮动画，避免每帧重复构建
  late final Animation<double> _photoTranslate;
  late final Animation<double> _photoOpacity;
  late final Animation<double> _relationTranslate;
  late final Animation<double> _relationOpacity;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _photoTranslate = CurvedAnimation(
      parent: _expandController,
      curve: const Interval(0.05, 1.0, curve: Curves.easeOutCubic),
    );
    _photoOpacity = CurvedAnimation(
      parent: _expandController,
      curve: const Interval(0.05, 0.85, curve: Curves.easeOut),
    );
    _relationTranslate = CurvedAnimation(
      parent: _expandController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    );
    _relationOpacity = CurvedAnimation(
      parent: _expandController,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  /// 收起展开菜单（供外部调用，如画布点击时）
  void collapse() {
    if (_expanded) {
      setState(() => _expanded = false);
      _expandController.reverse();
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 展开时的半透明遮罩，点击收起
        if (_expanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: collapse,
              child: AnimatedOpacity(
                opacity: _expanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
        Positioned(
          right: 14,
          bottom: 14,
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 展开的子按钮（新关系 / 新图片）
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              // 子按钮动画：交错淡入+上滑
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // "新图片"子按钮
                  Transform.translate(
                    offset: Offset(0, 12 * (1 - _photoTranslate.value)),
                    child: Opacity(
                      opacity: _photoOpacity.value,
                      child: _SubActionButton(
                        icon: Icons.add_photo_alternate,
                        label: '新图片',
                        color: AppColors.washiGreen,
                        onTap: () {
                          collapse();
                          widget.onAddPhoto();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // "新关系"子按钮（最后出现）
                  Transform.translate(
                    offset: Offset(0, 12 * (1 - _relationTranslate.value)),
                    child: Opacity(
                      opacity: _relationOpacity.value,
                      child: _SubActionButton(
                        icon: Icons.note_add_outlined,
                        label: '新线索',
                        color: AppColors.redThread,
                        onTap: () {
                          collapse();
                          widget.onAddCard();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
          // 主 FAB（+ 按钮）
          _FabButton(
            expanded: _expanded,
            onTap: _toggle,
          ),
        ],
      ),
        ),
      ],
    );
  }
}

/// 主 FAB 按钮 —— "+" 图标，展开后旋转为 "×"
class _FabButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _FabButton({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: expanded ? '收起菜单' : '添加内容',
      button: true,
      child: PressScaleButton(
        scaleEnd: 0.92,
        onTap: onTap,
        builder: (context, isPressed, child) {
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.redThread,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.redThread.withValues(alpha: isPressed ? 0.5 : 0.4),
                  blurRadius: isPressed ? 16 : 12,
                  offset: Offset(0, isPressed ? 6 : 4),
                ),
                BoxShadow(
                  color: AppColors.redThreadDark.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: AnimatedRotation(
                turns: expanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: const Icon(
                  Icons.add,
                  size: 30,
                  color: AppColors.agedPaper,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 展开的子操作按钮 —— 图标 + 文字标签的水平布局
class _SubActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SubActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: PressScaleButton(
        scaleEnd: 0.95,
        onTap: onTap,
        builder: (context, isPressed, child) {
          return Container(
            height: 44,
            padding: const EdgeInsets.only(left: 16, right: 18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isPressed ? 0.98 : 0.94),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isPressed ? 0.25 : 0.18),
                  blurRadius: isPressed ? 12 : 8,
                  offset: Offset(0, isPressed ? 4 : 2),
                ),
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: AppColors.agedPaper),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.agedPaper,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 单个工具按钮 —— 仿古纸风格的圆角方形按钮
class ToolButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final String? semanticLabel;
  final String? tooltip;

  const ToolButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.color,
    this.iconColor,
    this.size = 40,
    this.iconSize = 20,
    this.semanticLabel,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = PressScaleButton(
      scaleEnd: 0.9,
      onTap: onTap,
      builder: (context, isPressed, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isPressed ? 0.98 : 0.94),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.sepia.withValues(alpha: isPressed ? 0.35 : 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isPressed ? 0.3 : 0.22),
                blurRadius: isPressed ? 10 : 7,
                offset: Offset(1, isPressed ? 4 : 3),
              ),
              BoxShadow(
                color: AppColors.sepia.withValues(alpha: 0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.inkBlack,
            ),
          ),
        );
      },
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        child: button,
      );
    }

    return button;
  }
}
