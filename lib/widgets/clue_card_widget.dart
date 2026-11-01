/// 侦探线索墙 —— 线索卡片组件
///
/// 线索卡片是线索墙的核心交互单元，模拟侦探在软木板上钉上的纸质线索卡。
/// 每张卡片显示人物/事件名称、标签和描述，顶部有图钉装饰，可附带照片。
///
/// 手势交互状态机：
/// ```
/// 指针按下 → 等待判定
///   ├── 未移动 + 短按释放 → 单击（选择卡片）
///   ├── 未移动 + 快速双击 → 双击（编辑卡片）
///   ├── 移动超过阈值（卡片区域）→ 拖拽（移动卡片）
///   ├── 移动超过阈值（图钉区域）→ 连线（开始创建红线连接）
///   └── 长按超时（卡片区域）→ 拖拽（移动卡片）
///       长按超时（图钉区域）→ 连线（开始创建红线连接）
/// ```
///
/// 使用 [GestureCoordinator] 进行手势消歧，避免多个卡片同时响应手势。
/// 卡片支持多种视觉状态：普通、悬浮（floating）、高亮（highlighted）、
/// 连线目标（connectingTarget）、主要选中（primary）。
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import '../theme/clue_type_style.dart';
import '../theme/wall_constants.dart';
import '../utils/gesture_coordinator.dart';
import '../utils/app_haptics.dart';
import 'painters/pushpin_decorator.dart';

/// 线索卡片组件 —— StatefulWidget
///
/// 渲染一张线索卡片，包含名称、标签、描述、图钉和连接徽章。
/// 通过 Listener（而非 GestureDetector）处理原始指针事件，实现精细的手势判定逻辑。
class ClueCardWidget extends StatefulWidget {
  /// 卡片数据模型，包含名称、标签、描述、旋转角度等
  final ClueCard card;

  /// 单击回调（选择卡片）
  final VoidCallback? onTap;

  /// 双击回调（编辑卡片）
  final VoidCallback? onDoubleTap;

  /// 拖拽开始回调，参数为全局坐标
  final void Function(Offset globalPosition)? onDragStart;

  /// 拖拽更新回调，参数为全局坐标
  final void Function(Offset globalPosition)? onDragUpdate;

  /// 拖拽结束回调
  final VoidCallback? onDragEnd;

  /// 图钉长按开始回调（开始连线），参数为全局坐标
  final void Function(Offset globalPosition)? onPinLongPressStart;

  /// 图钉长按移动回调（连线拖拽中），参数为全局坐标
  final void Function(Offset globalPosition)? onPinLongPressMove;

  /// 图钉长按结束回调（完成连线）
  final VoidCallback? onPinLongPressEnd;

  /// 画布缩放比例
  final double scale;

  /// 是否为当前连线的目标卡片（连线拖拽到此卡片时高亮）
  final bool isConnectingTarget;

  /// 是否高亮（与选中卡片有关联时高亮）
  final bool isHighlighted;

  /// 是否悬浮（选中卡片时，关联卡片微微浮起）
  final bool isFloating;

  /// 是否为主要选中卡片（当前选中的卡片，浮起幅度更大）
  final bool isPrimary;

  /// 父画布是否正在处理双指缩放手势
  final bool isCanvasPinching;

  /// 指针按下回调（通知父组件）
  final VoidCallback? onPointerDown;

  /// 指针抬起回调（通知父组件）
  final VoidCallback? onPointerUp;

  /// 共享浮动时间通知器（由父组件驱动，所有卡片共用一个 Ticker）
  final ValueNotifier<double>? floatTimeNotifier;

  const ClueCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onDoubleTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onPinLongPressStart,
    this.onPinLongPressMove,
    this.onPinLongPressEnd,
    this.scale = 1.0,
    this.isConnectingTarget = false,
    this.isHighlighted = false,
    this.isFloating = false,
    this.isPrimary = false,
    this.isCanvasPinching = false,
    this.onPointerDown,
    this.onPointerUp,
    this.floatTimeNotifier,
  });

  @override
  State<ClueCardWidget> createState() => _ClueCardWidgetState();
}

/// 线索卡片状态管理
///
/// 管理手势状态机、按下动画、拖拽速度追踪等。
/// 使用 [TickerProviderStateMixin] 驱动多个动画控制器。
class _ClueCardWidgetState extends State<ClueCardWidget>
    with TickerProviderStateMixin {
  static const List<String> _serifFallback = AppTypography.serifFallback;
  static const List<String> _handwritingFallback = AppTypography.handwritingFallback;

  /// 手势协调器，用于消歧多个卡片的手势竞争
  final _gestureCoordinator = GestureCoordinator();

  /// 指针按下时的本地坐标，用于计算移动距离判定拖拽
  Offset? _pointerDownPosition;

  /// 长按判定定时器，超时后触发拖拽或连线
  Timer? _longPressTimer;

  Offset? _latestGlobalPosition;

  /// 单击延迟定时器，用于区分单击和双击
  Timer? _tapTimer;

  /// 是否正在拖拽（移动卡片）
  bool _isDragging = false;

  /// 是否正在连线（从图钉拖出红线）
  bool _isConnecting = false;

  /// 指针是否已移动超过触摸阈值
  bool _hasMoved = false;

  /// 是否处于按下状态（驱动缩放动画）
  bool _isPressed = false;

  /// 当前命中卡片的触摸指针，用于识别并取消卡片级多指手势。
  final Set<int> _activePointers = <int>{};

  /// 卡片级手势是否已交给画布缩放处理，抑制后续点击/拖拽收尾。
  bool _gestureCancelledForCanvasPinch = false;

  /// 按下缩放动画控制器
  late AnimationController _pressedAnimationController;

  /// 选中呼吸光晕动画控制器
  late AnimationController _glowController;

  /// 连线目标脉冲动画控制器
  late AnimationController _targetPulseController;

  /// 入场动画控制器（卡片创建时缩放+淡入）
  late AnimationController _entranceController;

  /// 按下缩放动画（复用 CurvedAnimation，避免重复创建泄漏）
  late CurvedAnimation _pressedCurve;

  /// 连线目标脉冲动画值（0.0 → 1.0）
  late Animation<double> _targetPulseAnimation;

  /// 图钉是否处于按压状态（驱动按压缩放动画）
  final ValueNotifier<bool> _pinPressed = ValueNotifier(false);

  /// 浮动动画相位（基于卡片 ID，使不同卡片浮动不同步）
  late final double _floatPhase;

  /// 浮动动画周期（秒）
  static const double _floatPeriod = 4.0;

  /// 长按判定延迟：超过此时间未释放则视为长按
  static const Duration _longPressDelay =
      Duration(milliseconds: WallConstants.longPressDelayMs);

  /// 单击判定延迟：双击窗口期过后才触发单击，避免误触
  static const Duration _tapDelay = Duration(milliseconds: 250);

  /// 卡片区域的触摸移动阈值，超过此距离视为拖拽意图
  static const double _touchSlop = WallConstants.touchSlop;

  /// 图钉区域的触摸移动阈值，比卡片更小以便更快触发连线
  static const double _pinTouchSlop = WallConstants.pinTouchSlop;

  @override
  void initState() {
    super.initState();
    _pressedAnimationController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _pressedCurve = CurvedAnimation(
      parent: _pressedAnimationController,
      curve: Curves.easeInOut,
    );

    // 浮动相位：每张卡片有随机相位偏移，避免同步浮动
    _floatPhase = ((widget.card.id ?? 0) * 37 % 2000) / 2000.0;

    // 选中呼吸光晕：2.5 秒一个周期，缓慢脉动
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    if (widget.isPrimary) {
      _glowController.repeat(reverse: true);
    }

    // 连线目标脉冲：1.2 秒一个周期，快速脉动
    _targetPulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _targetPulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _targetPulseController,
        curve: Curves.easeInOut,
      ),
    );
    if (widget.isConnectingTarget) {
      _targetPulseController.repeat(reverse: true);
    }

    // 入场动画：300ms 缩放+淡入
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
  }

  @override
  void didUpdateWidget(covariant ClueCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isCanvasPinching && widget.isCanvasPinching) {
      _cancelLocalGestureForCanvasPinch();
    }
    if (widget.isPrimary && !oldWidget.isPrimary) {
      _glowController.repeat(reverse: true);
    } else if (!widget.isPrimary && oldWidget.isPrimary) {
      _glowController.stop();
      _glowController.reset();
    }
    if (widget.isConnectingTarget && !oldWidget.isConnectingTarget) {
      _targetPulseController.repeat(reverse: true);
    } else if (!widget.isConnectingTarget && oldWidget.isConnectingTarget) {
      _targetPulseController.stop();
      _targetPulseController.reset();
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _tapTimer?.cancel();
    _pinPressed.dispose();
    _targetPulseController.dispose();
    _glowController.dispose();
    _entranceController.dispose();
    _pressedCurve.dispose();
    _pressedAnimationController.dispose();
    super.dispose();
  }

  /// 根据共享时间计算当前卡片的浮动偏移量
  double _computeFloatOffset(double time) {
    final t = ((time / _floatPeriod) + _floatPhase) % 1.0;
    // 复现原始 AnimationController.repeat(reverse: true) + Curves.easeInOut 的效果
    final rawT = t < 0.5 ? t * 2.0 : 2.0 - t * 2.0;
    final curved = Curves.easeInOut.transform(rawT);
    return -0.5 + curved * 1.0; // -0.5 → +0.5
  }

  /// 设置按下状态并驱动缩放动画
  ///
  /// 按下时向前播放动画（缩小），释放时反向播放（恢复）。
  /// 仅在状态变化时触发，避免不必要的 setState。
  void _setPressed(bool pressed) {
    if (_isPressed != pressed) {
      setState(() {
        _isPressed = pressed;
      });
      if (pressed) {
        _pressedAnimationController.forward();
      } else {
        _pressedAnimationController.reverse();
      }
    }
  }

  /// 构建无障碍标签：线索：姓名，类型：地点，标签：标签1、标签2
  String _buildSemanticsLabel() {
    final card = widget.card;
    final tags = card.tags;
    final typeLabel = card.cardType.label;
    if (tags.isEmpty) return '线索：${card.name}，类型：$typeLabel';
    return '线索：${card.name}，类型：$typeLabel，标签：${tags.join('、')}';
  }

  /// 处理指针按下事件
  ///
  /// 根据触摸区域（卡片 or 图钉）进入不同的手势判定路径：
  /// - 图钉区域：长按超时后触发连线
  /// - 卡片区域：长按超时后触发拖拽
  ///
  /// 同时记录初始位置和时间，为后续的移动判定和速度计算做准备。
  void _handlePointerDown(PointerDownEvent event, {bool isPin = false}) {
    if (widget.card.id == null) return;

    widget.onPointerDown?.call();
    if (_activePointers.isEmpty) {
      _gestureCancelledForCanvasPinch = false;
    }
    _activePointers.add(event.pointer);

    if (widget.isCanvasPinching || _activePointers.length > 1) {
      _cancelLocalGestureForCanvasPinch();
      return;
    }

    _pointerDownPosition = event.localPosition;
    _hasMoved = false;
    _isDragging = false;
    _isConnecting = false;
    _latestGlobalPosition = event.position;
    _setPressed(true);

    if (isPin) {
      // 图钉区域：通知协调器并启动长按连线定时器
      _gestureCoordinator.onPinPointerDown(widget.card.id!, event.position);
      _startLongPressTimer(() {
        _startConnecting(_latestGlobalPosition ?? event.position);
      });
    } else {
      // 卡片区域：通知协调器并启动长按拖拽定时器
      _gestureCoordinator.onCardPointerDown(widget.card.id!, event.position);
      _startLongPressTimer(() {
        _startDragging(_latestGlobalPosition ?? event.position);
      });
    }
  }

  /// 处理指针移动事件
  ///
  /// 核心判定逻辑：
  /// 1. 计算移动距离，判断是否超过触摸阈值
  /// 2. 如果首次超过阈值且尚未进入拖拽/连线状态，则取消长按定时器，
  ///    根据触摸区域进入拖拽或连线模式
  /// 3. 如果已在拖拽状态，更新位置并计算瞬时速度（指数移动平均）
  /// 4. 如果已在连线状态，通知父组件更新连线终点
  void _handlePointerMove(PointerMoveEvent event, {bool isPin = false}) {
    _latestGlobalPosition = event.position;
    if (_gestureCancelledForCanvasPinch ||
        widget.isCanvasPinching ||
        _activePointers.length > 1) {
      return;
    }
    if (_pointerDownPosition == null) return;

    final delta = event.localPosition - _pointerDownPosition!;
    // 图钉区域使用更小的阈值，使连线更容易触发
    final slop = isPin ? _pinTouchSlop : _touchSlop;
    _hasMoved = delta.distance > slop;

    // 首次超过移动阈值：取消长按等待，直接进入拖拽或连线
    if (_hasMoved) {
      _tapTimer?.cancel();
      if (!_isDragging && !_isConnecting) {
        _longPressTimer?.cancel();
      }
    }

    if (_isDragging) {
      // 计算拖拽速度：使用指数移动平均平滑瞬时速度
      // 权重 0.6/0.4 使速度既有响应性又不会剧烈抖动
      widget.onDragUpdate?.call(event.position);
    } else if (_isConnecting) {
      // 连线中：通知父组件更新连线终点位置
      widget.onPinLongPressMove?.call(event.position);
    }
  }

  /// 处理指针抬起事件
  ///
  /// 根据当前手势状态决定最终行为：
  /// - 拖拽中 → 结束拖拽
  /// - 连线中 → 结束连线
  /// - 未移动 → 处理点击（单击/双击判定）
  void _handlePointerUp(PointerUpEvent event, {bool isPin = false}) {
    final wasCancelledForCanvasPinch = _gestureCancelledForCanvasPinch ||
        widget.isCanvasPinching ||
        _activePointers.length > 1;
    _activePointers.remove(event.pointer);

    if (wasCancelledForCanvasPinch) {
      _completeCancelledPointerSequence();
      return;
    }

    _longPressTimer?.cancel();
    _setPressed(false);
    widget.onPointerUp?.call();

    if (_isDragging) {
      widget.onDragEnd?.call();
      AppHaptics.dragEnd();
    } else if (_isConnecting) {
      widget.onPinLongPressEnd?.call();
    } else if (!_hasMoved) {
      // 未移动：进入点击判定（区分单击和双击）
      _handleTap(event.position);
    }

    _gestureCoordinator.onPointerUp(event.position);
    _resetGestureState();
  }

  /// 处理指针取消事件（如系统弹窗打断）
  ///
  /// 取消所有定时器，恢复按下状态，重置手势状态。
  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _longPressTimer?.cancel();
    _tapTimer?.cancel();
    _setPressed(false);
    widget.onPointerUp?.call();
    _gestureCoordinator.onPointerCancel();
    _resetGestureState();
  }

  void _cancelLocalGestureForCanvasPinch() {
    final hadActiveGesture = _activePointers.isNotEmpty ||
        _pointerDownPosition != null ||
        _isDragging ||
        _isConnecting ||
        _isPressed ||
        (_longPressTimer?.isActive ?? false) ||
        (_tapTimer?.isActive ?? false);

    _longPressTimer?.cancel();
    _tapTimer?.cancel();
    _setPressed(false);

    if (hadActiveGesture) {
      _gestureCancelledForCanvasPinch = true;
    }

    _gestureCoordinator.onPointerCancel();
    _resetGestureState();
  }

  void _completeCancelledPointerSequence() {
    _longPressTimer?.cancel();
    _tapTimer?.cancel();
    _setPressed(false);
    widget.onPointerUp?.call();

    if (_activePointers.isEmpty) {
      _gestureCoordinator.onPointerCancel();
      _resetGestureState();
    }
  }

  /// 启动长按判定定时器
  ///
  /// 超时后执行 [callback]，触发拖拽或连线。
  void _startLongPressTimer(VoidCallback callback) {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(_longPressDelay, callback);
  }

  /// 进入拖拽模式
  ///
  /// 记录初始位置和时间，通知父组件拖拽开始，触发触觉反馈。
  void _startDragging(Offset position) {
    if (_gestureCancelledForCanvasPinch || widget.isCanvasPinching) return;
    setState(() {
      _isDragging = true;
    });
    _pressedAnimationController.forward();
    widget.onDragStart?.call(position);
    AppHaptics.dragStart();
  }

  /// 进入连线模式
  ///
  /// 通知父组件从图钉位置开始拖出红线。
  void _startConnecting(Offset position) {
    if (_gestureCancelledForCanvasPinch || widget.isCanvasPinching) return;
    _isConnecting = true;
    widget.onPinLongPressStart?.call(position);
  }

  /// 处理点击判定 —— 区分单击和双击
  ///
  /// 使用 [GestureCoordinator.shouldRecognizeDoubleTap] 判断是否为双击：
  /// - 双击：立即触发 [onDoubleTap]
  /// - 单击：延迟 250ms 触发（等待双击窗口期结束），避免误判
  void _handleTap(Offset position) {
    _tapTimer?.cancel();

    if (_gestureCoordinator.shouldRecognizeDoubleTap(position)) {
      // 双击：直接触发编辑
      widget.onDoubleTap?.call();
      AppHaptics.medium();
    } else {
      // 单击：延迟触发，等待可能的双击
      _tapTimer = Timer(_tapDelay, () {
        widget.onTap?.call();
        AppHaptics.light();
      });
    }
  }

  /// 重置所有手势状态
  ///
  /// 在指针抬起或取消后调用，清除所有中间状态。
  void _resetGestureState() {
    _pointerDownPosition = null;
    _isDragging = false;
    _isConnecting = false;
    _hasMoved = false;
    _latestGlobalPosition = null;
    if (_activePointers.isEmpty) {
      _gestureCancelledForCanvasPinch = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 悬浮状态的装饰：红色边框 + 加深阴影，模拟卡片被"提起"的效果
    // 光晕阴影由 AnimatedBuilder 单独驱动，不在此处计算
    final floatingDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(3),
      border: Border.all(
        // 主要选中卡片边框更粗更明显
        color: AppColors.redThread
            .withValues(alpha: widget.isPrimary ? 0.5 : 0.3),
        width: widget.isPrimary ? 2.0 : 1.4,
      ),
      boxShadow: [
        BoxShadow(
          // 主要选中卡片阴影更深更远
          color: Colors.black.withValues(alpha: widget.isPrimary ? 0.45 : 0.35),
          offset: Offset(0, widget.isPrimary ? 10 : 6),
          blurRadius: widget.isPrimary ? 28 : 18,
          spreadRadius: widget.isPrimary ? 5 : 2.5,
        ),
        // 添加第二个阴影层，增强立体感
        BoxShadow(
          color: AppColors.redThread.withValues(alpha: widget.isPrimary ? 0.15 : 0.08),
          offset: const Offset(0, 2),
          blurRadius: widget.isPrimary ? 12 : 8,
          spreadRadius: widget.isPrimary ? 2 : 1,
        ),
      ],
    );

    // 根据优先级选择装饰样式：连线目标 > 高亮 > 悬浮 > 无装饰
    final pulseValue = _targetPulseAnimation.value;
    final targetDecoration = widget.isConnectingTarget
        ? BoxDecoration(
            // 连线目标：脉冲红色边框 + 红色光晕，提示用户可以释放完成连线
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: AppColors.redThread
                  .withValues(alpha: 0.4 + pulseValue * 0.3),
              width: 2.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.redThread
                    .withValues(alpha: 0.12 + pulseValue * 0.12),
                blurRadius: 12 + pulseValue * 6,
                spreadRadius: 2 + pulseValue * 2,
              ),
              BoxShadow(
                color: AppColors.redThread
                    .withValues(alpha: 0.06 + pulseValue * 0.06),
                blurRadius: 6 + pulseValue * 4,
                spreadRadius: 1 + pulseValue,
              ),
            ],
          )
        : widget.isHighlighted
            ? BoxDecoration(
                // 高亮状态：橙色边框 + 橙色光晕，表示与选中卡片有关联
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: AppColors.tagOrange.withValues(alpha: 0.7),
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tagOrange.withValues(alpha: 0.22),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppColors.tagOrange.withValues(alpha: 0.1),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              )
            : widget.isFloating
                ? floatingDecoration
                : null;

    // 拖拽状态：更深阴影 + 轻微放大，模拟卡片被"提起"
    final dragDecoration = _isDragging
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              AppShadows.cardDrag,
            ],
          )
        : null;

    final effectiveDecoration = dragDecoration ?? targetDecoration;

    return FadeTransition(
      opacity: _entranceController,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
        ),
        child: AnimatedBuilder(
      animation: _pressedCurve,
      builder: (context, child) {
        return Transform.scale(
          scale: Tween<double>(begin: 1.0, end: WallConstants.pressScale).transform(_pressedCurve.value),
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 卡片主体区域：处理卡片级别的手势（拖拽、点击）
          Semantics(
            label: _buildSemanticsLabel(),
            hint: '点击选择，双击编辑，长按拖动',
            child: Listener(
              onPointerDown: (e) => _handlePointerDown(e, isPin: false),
              onPointerMove: (e) => _handlePointerMove(e, isPin: false),
              onPointerUp: (e) => _handlePointerUp(e, isPin: false),
              onPointerCancel: _handlePointerCancel,
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _targetPulseController,
                builder: (context, child) => child!,
                child: AnimatedSlide(
                // 悬浮时微微上移，主要卡片上移更多
                offset: widget.isFloating
                    ? Offset(0, widget.isPrimary ? -0.03 : -0.018)
                    : Offset.zero,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: AnimatedScale(
                  // 悬浮时微微放大，主要卡片放大更多
                  scale: widget.isFloating
                      ? (widget.isPrimary ? 1.08 : 1.04)
                      : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      // 仅悬浮装饰需要光晕脉动，其他装饰直接透传
                      final glowAlpha = widget.isPrimary
                          ? 0.08 + _glowController.value * 0.12
                          : 0.12;
                      final glowDecoration = effectiveDecoration == floatingDecoration
                          ? floatingDecoration.copyWith(
                              boxShadow: [
                                ...floatingDecoration.boxShadow ?? [],
                                if (widget.isPrimary)
                                  BoxShadow(
                                    color: AppColors.redThread.withValues(alpha: glowAlpha),
                                    offset: const Offset(0, 3),
                                    blurRadius: 14,
                                    spreadRadius: 3,
                                  ),
                              ],
                            )
                          : effectiveDecoration;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        decoration: glowDecoration,
                        child: child,
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildCardBody(context),
                      ],
                    ),
                  ),
                ),
              ),
              ),
            ),
          ),
          // 图钉区域：独立的手势处理区域，长按触发连线
          Positioned(
            top: 0,
            left: widget.card.width / 2 - WallConstants.pushpinCenterOffset,
            child: Semantics(
              label: '图钉',
              hint: '长按图钉开始连线',
              child: Listener(
                onPointerDown: (e) {
                  _pinPressed.value = true;
                  _handlePointerDown(e, isPin: true);
                },
                onPointerMove: (e) => _handlePointerMove(e, isPin: true),
                onPointerUp: (e) {
                  _pinPressed.value = false;
                  _handlePointerUp(e, isPin: true);
                },
                onPointerCancel: (e) {
                  _pinPressed.value = false;
                  _handlePointerCancel(e);
                },
                behavior: HitTestBehavior.opaque,
                // 图钉触摸区域 44x44，比视觉尺寸大，提升触摸友好性
                child: SizedBox(
                  width: WallConstants.pushpinHitArea,
                  height: WallConstants.pushpinHitArea,
                  child: Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _pinPressed,
                      builder: (context, pressed, _) => Pushpin(
                        color: widget.card.cardType.pinColor,
                        isPressed: pressed,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }

  /// 构建卡片主体 —— 旋转容器 + 纸张外观
  ///
  /// 卡片根据 [card.rotation] 微微旋转，模拟真实钉在墙上的纸张角度。
  /// 双层阴影（近处小阴影 + 远处大阴影）营造纸张悬浮在软木板上的立体感。
  Widget _buildCardBody(BuildContext context) {
    final floatNotifier = widget.floatTimeNotifier;
    if (floatNotifier == null) {
      // 无共享 ticker 时使用静态偏移（降级处理）
      return _buildCardBodyWithOffset(context, 0);
    }
    return ValueListenableBuilder<double>(
      valueListenable: floatNotifier,
      builder: (context, time, child) {
        final offset = _computeFloatOffset(time);
        return _buildCardBodyWithOffset(context, offset);
      },
    );
  }

  Widget _buildCardBodyWithOffset(BuildContext context, double floatOffset) {
    final lift = (0.5 - floatOffset).clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(0, floatOffset),
      child: Transform.rotate(
        angle: widget.card.rotation,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(1),
            border: Border.all(
              color: AppColors.sepia.withValues(alpha: 0.08 + lift * 0.04),
              width: 0.35,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18 + lift * 0.06),
                offset: Offset(1, 2.5 + lift * 1.5),
                blurRadius: 5.0 + lift * 2.0,
                spreadRadius: lift * 0.5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07 + lift * 0.04),
                offset: Offset(1.5, 7.0 + lift * 3.0),
                blurRadius: 14 + lift * 8,
                spreadRadius: -3 + lift * 2,
              ),
            ],
          ),
          child: ClipPath(
            clipper: _TornPaperClipper(seed: widget.card.id ?? 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PaperGrainPainter(seed: widget.card.id ?? 0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: WallConstants.cardContentPaddingH,
                      vertical: WallConstants.cardContentPaddingV),
                  child: _buildCardContent(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 计算文字区域的有效最大宽度
  double _computeContentMaxWidth() => widget.card.width;

  /// 类型徽章 —— 类型色描边 + 图标 + 中文标签
  ///
  /// 固定作为第一个标签展示，即使卡片没有任何标签也能一眼识别线索类型。
  Widget _buildTypeBadge() {
    final type = widget.card.cardType;
    final color = type.color;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: WallConstants.cardTagPaddingH,
          vertical: WallConstants.cardTagPaddingV),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.24), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon,
              size: WallConstants.cardTypeIconSize,
              color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 3),
          Text(
            type.label,
            style: TextStyle(
              fontFamily: AppTypography.harmonyOS,
              fontSize: WallConstants.cardTypeFontSize,
              color: color.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }

  /// 布局从上到下：
  /// 1. 人物/事件名称（Caveat 手写体，最多2行）
  /// 2. 类型徽章 + 标签列表（类型徽章固定在最前，彩色小标签循环使用5种颜色）
  /// 3. 描述文字（SourceSerif4 衬线体，最多3行）
  Widget _buildCardContent(BuildContext context) {
    final tagColors = [
      AppColors.tagBlue,
      AppColors.tagGreen,
      AppColors.tagOrange,
      AppColors.sageGreen,
      AppColors.dustyBlue,
    ];

    final contentMaxWidth = _computeContentMaxWidth();

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: contentMaxWidth < widget.card.width
            ? contentMaxWidth
            : widget.card.width,
        maxWidth: contentMaxWidth,
        minHeight: widget.card.height,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 人物/事件名称 —— Caveat 手写体（中文回退霞鹜文楷）
          Text(
            widget.card.name,
            style: const TextStyle(
              fontFamily: AppTypography.caveat,
              fontFamilyFallback: _handwritingFallback,
              color: AppColors.inkBlack,
              fontSize: WallConstants.cardNameFontSize,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: 0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // 类型徽章 + 标签列表
          const SizedBox(height: 7),
          Wrap(
            spacing: 4,
            runSpacing: 3,
            children: [
              _buildTypeBadge(),
              ...widget.card.tags.asMap().entries.map((entry) {
                final color = tagColors[entry.key % tagColors.length];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: WallConstants.cardTagPaddingH,
                      vertical: WallConstants.cardTagPaddingV),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontFamily: AppTypography.harmonyOS,
                      fontSize: WallConstants.cardTagFontSize,
                      color: color.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                    ),
                  ),
                );
              }),
            ],
          ),
          // 描述文字 —— SourceSerif4 衬线体
          if (widget.card.description != null &&
              widget.card.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              height: WallConstants.cardSeparatorHeight,
              margin: const EdgeInsets.only(bottom: 5),
              color: AppColors.sepia.withValues(alpha: 0.12),
            ),
            Text(
              widget.card.description!,
              style: const TextStyle(
                fontFamily: AppTypography.sourceSerif4,
                fontFamilyFallback: _serifFallback,
                color: AppColors.inkLight,
                fontSize: WallConstants.cardDescFontSize,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// 纸纹绘制器 —— 为卡片添加微妙的纸张质感
///
/// 绘制四层效果：
/// 1. 泛黄层：微暖色调渐变，模拟旧纸张的氧化泛黄
/// 2. 随机噪点：模拟纸张纤维的微观纹理
/// 3. 极淡横线：模拟笔记本行线，增加手写笔记的真实感
/// 4. 边缘磨损：四边加深，模拟纸张边缘的老化磨损
/// 使用卡片 ID 作为随机种子，确保每张卡片的噪点分布固定且唯一。
class _PaperGrainPainter extends CustomPainter {
  final int seed;

  _PaperGrainPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);

    // 层1：泛黄效果 —— 整体微暖色调叠加
    final yellowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.coffeeStain.withValues(alpha: 0.025),
          AppColors.coffeeStain.withValues(alpha: 0.01),
          AppColors.coffeeStain.withValues(alpha: 0.02),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), yellowPaint);

    // 层2：随机噪点 —— 模拟纸张纤维
    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < WallConstants.paperGrainDotCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = rng.nextDouble() * WallConstants.paperGrainDotRadiusMax +
          WallConstants.paperGrainDotRadiusMin;
      final alpha = rng.nextDouble() * WallConstants.paperGrainDotAlphaMax +
          WallConstants.paperGrainDotAlphaMin;
      dotPaint.color = AppColors.sepia.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }

    // 层3：极淡横线 —— 模拟笔记本行线
    final linePaint = Paint()
      ..color = AppColors.sepia.withValues(alpha: 0.04)
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;
    for (double y = WallConstants.paperGrainLineSpacing;
        y < size.height;
        y += WallConstants.paperGrainLineSpacing) {
      // 微小的水平偏移，模拟手撕纸张后行线不完全对齐
      final offsetX =
          (rng.nextDouble() - 0.5) * WallConstants.paperGrainLineJitter;
      canvas.drawLine(
        Offset(2 + offsetX, y),
        Offset(size.width - 2 + offsetX, y),
        linePaint,
      );
    }

    // 层4：边缘磨损 —— 四边加深，模拟纸张边缘氧化磨损
    const edgeWear = WallConstants.paperGrainEdgeWear;
    // 上边
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, edgeWear),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sepia.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, edgeWear)),
    );
    // 下边
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - edgeWear, size.width, edgeWear),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.sepia.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(
            0, size.height - edgeWear, size.width, edgeWear)),
    );
    // 左边
    canvas.drawRect(
      Rect.fromLTWH(0, 0, edgeWear, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.sepia.withValues(alpha: 0.04),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, edgeWear, size.height)),
    );
    // 右边
    canvas.drawRect(
      Rect.fromLTWH(size.width - edgeWear, 0, edgeWear, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            AppColors.sepia.withValues(alpha: 0.04),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(
            size.width - edgeWear, 0, edgeWear, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _PaperGrainPainter oldDelegate) =>
      seed != oldDelegate.seed;
}

/// 毛边撕裂裁剪器 —— 模拟从笔记本随手撕下的纸张边缘
///
/// 使用卡片 ID 作为随机种子，确保每张卡片的撕裂形状固定且唯一。
/// 四条边都有不规则锯齿，上下边缘振幅更大（主撕裂方向），
/// 左右边缘振幅较小（侧面通常撕得更整齐）。
class _TornPaperClipper extends CustomClipper<Path> {
  final int seed;

  _TornPaperClipper({required this.seed});

  @override
  Path getClip(Size size) {
    final rng = Random(seed);
    final path = Path();
    const step = 6.0; // 锯齿采样步长（像素），越小越密集
    const topAmp = 3.0; // 上边缘最大偏移
    const bottomAmp = 3.5; // 下边缘最大偏移（撕裂更明显）
    const sideAmp = 2.0; // 左右边缘最大偏移

    // 上边缘：从左到右
    path.moveTo(-1, -1);
    for (double x = 0; x <= size.width; x += step) {
      final dy = (rng.nextDouble() * 2 - 1) * topAmp;
      path.lineTo(x, dy);
    }
    path.lineTo(size.width + 1, -1);

    // 右边缘：从上到下
    for (double y = 0; y <= size.height; y += step) {
      final dx = size.width + (rng.nextDouble() * 2 - 1) * sideAmp;
      path.lineTo(dx, y);
    }
    path.lineTo(size.width + 1, size.height + 1);

    // 下边缘：从右到左
    for (double x = size.width; x >= 0; x -= step) {
      final dy = size.height + (rng.nextDouble() * 2 - 1) * bottomAmp;
      path.lineTo(x, dy);
    }
    path.lineTo(-1, size.height + 1);

    // 左边缘：从下到上
    for (double y = size.height; y >= 0; y -= step) {
      final dx = (rng.nextDouble() * 2 - 1) * sideAmp;
      path.lineTo(dx, y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _TornPaperClipper oldClipper) =>
      seed != oldClipper.seed;
}
