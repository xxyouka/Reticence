/// 应用对话框共享组件库
///
/// 提供侦探线索墙应用中所有对话框共用的基础 UI 组件，确保视觉风格统一。
/// 包含三个核心组件：
///
/// - [AppDialogShell]：对话框外壳容器，提供统一的背景色、圆角和阴影
/// - [AppDragHandle]：底部抽屉拖拽手柄，视觉提示用户可下拉关闭
/// - [AppTextField]：统一样式的文本输入框，模拟旧纸张上的手写输入感
///
/// 设计原则：
/// - 所有对话框组件必须通过这些共享组件构建，避免样式碎片化
/// - 色彩体系严格使用 AppColors 中定义的侦探主题色
/// - 输入框的视觉风格模拟旧纸张上墨水笔书写的效果：
///   半透明旧纸色填充 + 深棕色边框 + 墨黑色文字
library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 对话框通用布局常量
///
/// 集中管理所有对话框中重复出现的间距、字号和图标尺寸，
/// 避免在各对话框文件中散落相同的魔法数字。
class DialogConstants {
  DialogConstants._();

  // ---- 水平内边距 ----
  static const double horizontalPadding = 24.0; // 对话框内容区水平内边距

  // ---- 标题行 ----
  static const double titleIconSize = 18.0; // 标题图标尺寸
  static const double titleIconPadding = 8.0; // 标题图标容器内边距
  static const double titleIconBorderRadius = 8.0; // 标题图标容器圆角
  static const double titleIconGap = 12.0; // 标题图标与文字间距
  static const double titleFontSize = 18.0; // 标题字号
  static const double titleLetterSpacing = 0.3; // 标题字间距

  // ---- 段落间距 ----
  static const double sectionGapSmall = 10.0; // 输入框之间间距
  static const double sectionGapMedium = 18.0; // 标题与内容之间间距
  static const double sectionGapLarge = 20.0; // 内容与按钮之间间距
  static const double bottomPadding = 24.0; // 对话框底部内边距

  // ---- 按钮行 ----
  static const double buttonGap = 8.0; // 按钮之间间距
  static const double buttonHeight = 40.0; // 操作按钮高度
  static const double buttonBorderRadius = 8.0; // 操作按钮圆角
  static const double buttonFontSize = 13.0; // 按钮字号
}

/// 对话框入场动画 Mixin
///
/// 为所有底部抽屉对话框提供统一的入场动画：
/// - 500ms 的淡入 + 上滑动画
/// - [staggeredInterval] 方法用于构建交错动画区间
///
/// 使用方式：在 State 类上 with 此 mixin，然后在 build 中使用
/// `FadeTransition` + `SlideTransition` 配合 `staggeredInterval` 即可。
mixin DialogEntranceMixin<T extends StatefulWidget>
    on SingleTickerProviderStateMixin<T> {
  late final AnimationController entranceController;

  @override
  void initState() {
    super.initState();
    entranceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    entranceController.dispose();
    super.dispose();
  }

  /// 构建交错动画区间
  ///
  /// [start] 和 [end] 取值范围 0.0 ~ 1.0，表示在总动画中的时间占比。
  Animation<double> staggeredInterval(double start, double end) {
    return CurvedAnimation(
      parent: entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }
}

/// 对话框标题行
///
/// 统一的标题行布局：左侧图标容器 + 间距 + 标题文字 + 可选右侧子组件。
/// 所有对话框标题均应通过此组件构建，确保视觉一致性。
class AppDialogTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? iconBgColor;
  final Widget? trailing;

  const AppDialogTitle({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.iconBgColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: DialogConstants.horizontalPadding),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DialogConstants.titleIconPadding),
            decoration: BoxDecoration(
              color: iconBgColor ??
                  AppColors.redThread.withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(DialogConstants.titleIconBorderRadius),
            ),
            child: Icon(
              icon,
              size: DialogConstants.titleIconSize,
              color: iconColor ?? AppColors.redThread.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: DialogConstants.titleIconGap),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.inkBlack.withValues(alpha: 0.85),
                fontSize: DialogConstants.titleFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: DialogConstants.titleLetterSpacing,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 对话框外壳容器
///
/// 为所有底部抽屉式对话框提供统一的外层包装，包含：
/// - 底部安全区域适配（键盘弹出时自动调整间距）
/// - 旧纸色（agedPaper / paperWhiteDark）背景
/// - 顶部圆角
/// - 向上投射的阴影
///
/// 使用方式：将对话框内容作为 [child] 传入即可。
/// 所有对话框（AddCardDialog、CardDetailDialog、ConnectionDetailDialog 等）
/// 都通过此组件包裹，确保视觉一致性。
class AppDialogShell extends StatelessWidget {
  /// 对话框内容组件
  final Widget child;

  const AppDialogShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 适配键盘弹出时的底部间距，确保输入框不被键盘遮挡
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          // 仅顶部圆角，符合底部抽屉的标准视觉规范
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          // 向上投射的柔和阴影，增强面板的浮起层次感
          boxShadow: const [
            BoxShadow(
              color: AppColors.bottomSheetShadow,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        // 小屏 + 键盘弹出时内容可滚动，避免类型选择器把按钮挤出屏幕
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: child,
        ),
      ),
    );
  }
}

/// 底部抽屉拖拽手柄
///
/// 在对话框顶部显示一个半透明的深棕色横条，作为视觉提示告诉用户
/// 可以下拉关闭底部抽屉。这是 Material Design 底部抽屉的标准交互模式。
///
/// 视觉规格：
/// - 宽度 32px，高度 3.5px
/// - 深棕色，透明度 0.2（低调不抢眼）
/// - 上下各留间距，与对话框内容保持呼吸感
class AppDragHandle extends StatelessWidget {
  const AppDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 32,
            height: 3.5,
            decoration: BoxDecoration(
              // 低透明度深棕色，低调但可辨识
              color: AppColors.sepia.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// 统一样式的操作按钮
///
/// 为所有对话框中的操作按钮提供一致的视觉风格。
/// 通过 [filled] 参数控制两种视觉样式：
/// - filled = true：实心填充按钮，用于主要操作（保存）
/// - filled = false：描边按钮，用于次要或危险操作（连线、删除）
///
/// 按下时有缩放反馈动画，与其他按钮组件保持一致的交互手感。
class AppActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final bool filled;
  final bool isLoading;
  final VoidCallback onTap;

  const AppActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<AppActionButton> createState() => _AppActionButtonState();
}

class _AppActionButtonState extends State<AppActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.isLoading) _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: SizedBox(
          height: DialogConstants.buttonHeight,
          child: Container(
            decoration: BoxDecoration(
              color: widget.filled ? widget.color : Colors.transparent,
              borderRadius: BorderRadius.circular(DialogConstants.buttonBorderRadius),
              border: widget.filled
                  ? null
                  : Border.all(
                      color: widget.color.withValues(alpha: 0.4), width: 1),
              boxShadow: widget.filled
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.filled
                            ? AppColors.surfaceOf(context)
                                .withValues(alpha: 0.9)
                            : widget.color,
                      ),
                    )
                  : Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.filled
                            ? AppColors.surfaceOf(context)
                                .withValues(alpha: 0.95)
                            : widget.color,
                        fontSize: DialogConstants.buttonFontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 统一样式的文本输入框
///
/// 为所有对话框中的文本输入提供一致的视觉风格，模拟在旧纸张上
/// 用墨水笔书写的视觉效果。
///
/// 聚焦时边框和阴影会平滑过渡，提供即时的视觉反馈。
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final int maxLines;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.textInputAction,
    this.maxLines = 1,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsFocusNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _isFocused = _focusNode.hasFocus;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.redThread.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        textInputAction: widget.textInputAction,
        maxLines: widget.maxLines,
        onSubmitted:
            widget.onSubmitted != null ? (_) => widget.onSubmitted!() : null,
        style: TextStyle(
          color: AppColors.textOf(context).withValues(alpha: 0.85),
          fontSize: 14,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: AppColors.hintOf(context),
            fontSize: 14,
          ),
          filled: true,
          fillColor: AppColors.inputFillOf(context),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.inputBorderOf(context),
              width: 0.8,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.redThread.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// 统一风格的确认删除底部抽屉
///
/// 替代原生 AlertDialog，与应用的底部抽屉视觉语言保持一致。
/// 顶部显示带摇晃动画的警告图标，强化删除操作的严肃感。
class AppConfirmSheet extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const AppConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  State<AppConfirmSheet> createState() => _AppConfirmSheetState();
}

class _AppConfirmSheetState extends State<AppConfirmSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.06), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.06, end: -0.06), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.04), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.04, end: -0.03), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeOutCubic,
    ));
    // 延迟启动，等底部抽屉滑入后再摇晃
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _shakeController.forward();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppDragHandle(),
          // 警告图标（带摇晃动画）
          Center(
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _shakeAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.redThread.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.redThread.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.redThread.withValues(alpha: 0.8),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DialogConstants.horizontalPadding),
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textOf(context).withValues(alpha: 0.85),
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DialogConstants.horizontalPadding),
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondaryOf(context),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DialogConstants.horizontalPadding),
            child: Row(
              children: [
                Expanded(
                  child: AppActionButton(
                    label: '取消',
                    color: AppColors.warmGray,
                    filled: false,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: DialogConstants.buttonGap),
                Expanded(
                  child: AppActionButton(
                    label: '删除',
                    color: AppColors.redThread.withValues(alpha: 0.88),
                    filled: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onConfirm();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
