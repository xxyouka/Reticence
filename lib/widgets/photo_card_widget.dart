/// 侦探线索墙 —— 照片卡片组件
///
/// 照片卡片是线索墙上的独立照片展示单元，模拟侦探钉在软木板上的洗印照片。
/// 与 [ClueCardWidget] 类似，但更简洁：图钉支持连线但没有图钉连线的复杂手势协调。
///
/// 手势交互：
/// ```
/// 指针按下 → 等待判定
///   ├── 在图钉区域：长按 → 连线模式（从图钉拖拽创建红线）
///   ├── 未移动 + 释放 → 点击（选择照片）
///   ├── 未移动 + 快速双击 → 双击（编辑照片）
///   ├── 移动超过阈值 → 拖拽（移动照片）
///   └── 长按超时 → 拖拽（移动照片）
/// ```
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/photo_card_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';
import '../theme/wall_constants.dart';
import '../utils/app_haptics.dart';
import '../utils/gesture_coordinator.dart';
import 'painters/pushpin_decorator.dart';

/// 照片卡片组件 —— StatefulWidget
///
/// 渲染一张独立的照片卡片，包含图片、手写风格标题和可交互的图钉。
/// 通过 Listener 处理原始指针事件，实现拖拽、点击和图钉连线的判定。
class PhotoCardWidget extends StatefulWidget {
  /// 照片数据模型，包含图片路径、标题、旋转角度等
  final PhotoCard photo;

  /// 点击回调（选择照片）
  final VoidCallback? onTap;

  /// 双击回调（编辑照片）
  final VoidCallback? onDoubleTap;

  /// 拖拽开始回调，参数为全局坐标
  final Function(Offset globalPosition)? onDragStart;

  /// 拖拽更新回调，参数为全局坐标
  final Function(Offset globalPosition)? onDragUpdate;

  /// 拖拽结束回调
  final VoidCallback? onDragEnd;

  /// 是否高亮（与选中卡片有关联时高亮）
  final bool isHighlighted;

  /// 是否为主要选中项（当前选中的照片，视觉强调更强）
  final bool isPrimary;

  /// 指针按下回调（通知父组件）
  final VoidCallback? onPointerDown;

  /// 指针抬起回调（通知父组件）
  final VoidCallback? onPointerUp;

  /// 图钉长按开始回调（进入连线模式），参数为全局坐标
  final Function(Offset globalPosition)? onPinLongPressStart;

  /// 图钉长按移动回调（更新连线位置），参数为全局坐标
  final Function(Offset globalPosition)? onPinLongPressMove;

  /// 图钉长按结束回调（完成连线）
  final VoidCallback? onPinLongPressEnd;

  /// 是否为连线目标（连线模式下非源照片显示为可连接目标）
  final bool isConnectingTarget;

  const PhotoCardWidget({
    super.key,
    required this.photo,
    this.onTap,
    this.onDoubleTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.isHighlighted = false,
    this.isPrimary = false,
    this.onPointerDown,
    this.onPointerUp,
    this.onPinLongPressStart,
    this.onPinLongPressMove,
    this.onPinLongPressEnd,
    this.isConnectingTarget = false,
  });

  @override
  State<PhotoCardWidget> createState() => _PhotoCardWidgetState();
}

/// 照片卡片状态管理
///
/// 管理手势状态机（拖拽/点击/连线/双击）和按下缩放动画。
class _PhotoCardWidgetState extends State<PhotoCardWidget>
    with TickerProviderStateMixin {
  /// 手势协调器，用于双击检测
  final _gestureCoordinator = GestureCoordinator();

  /// 指针按下时的本地坐标，用于计算移动距离判定拖拽
  Offset? _pointerDownPosition;

  /// 长按判定定时器，超时后触发拖拽
  Timer? _longPressTimer;

  /// 单击延迟定时器，用于区分单击和双击
  Timer? _tapTimer;

  /// 是否正在拖拽
  bool _isDragging = false;

  /// 指针是否已移动超过触摸阈值
  bool _hasMoved = false;

  /// 是否处于按下状态（驱动缩放动画）
  bool _isPressed = false;

  /// 是否正在连线模式（从图钉拖拽中）
  bool _isConnecting = false;
  bool _pointerStartedOnPin = false;

  /// 触摸移动阈值
  static const double _touchSlop = WallConstants.touchSlop;

  /// 图钉区域的触摸移动阈值（更小，使连线更容易触发）
  static const double _pinTouchSlop = WallConstants.pinTouchSlop;

  /// 单击判定延迟：双击窗口期过后才触发单击，避免误判
  static const Duration _tapDelay =
      Duration(milliseconds: WallConstants.longPressDelayMs);

  /// 按下缩放动画控制器
  late AnimationController _pressedAnimationController;

  /// 选中呼吸光晕动画控制器
  late AnimationController _glowController;

  /// 连线目标脉冲动画控制器
  late AnimationController _targetPulseController;

  /// 入场动画控制器（照片创建时缩放+淡入）
  late AnimationController _entranceController;

  /// 按下缩放动画值（1.0 → 0.98）
  late Animation<double> _pressedScaleAnimation;

  /// 连线目标脉冲动画值（0.0 → 1.0）
  late Animation<double> _targetPulseAnimation;

  /// 图钉是否处于按压状态（驱动按压缩放动画）
  final ValueNotifier<bool> _pinPressed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _pressedAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pressedScaleAnimation = Tween<double>(begin: 1.0, end: WallConstants.pressScale).animate(
      CurvedAnimation(
        parent: _pressedAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 选中呼吸光晕：2.5 秒一个周期
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    if (widget.isPrimary) {
      _glowController.repeat(reverse: true);
    }

    // 连线目标脉冲：1.2 秒一个周期
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

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
  }

  @override
  void didUpdateWidget(covariant PhotoCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _pressedAnimationController.dispose();
    super.dispose();
  }

  /// 设置按下状态并驱动缩放动画
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

  /// 处理指针按下事件
  void _handlePointerDown(PointerDownEvent event, {bool isPin = false}) {
    widget.onPointerDown?.call();
    _pointerDownPosition = event.localPosition;
    _isDragging = false;
    _hasMoved = false;
    _isConnecting = false;
    _pointerStartedOnPin = isPin;
    _setPressed(true);

    if (isPin) {
      // 图钉区域：长按触发连线
      _longPressTimer = Timer(_tapDelay, () {
        _isConnecting = true;
        widget.onPinLongPressStart?.call(event.position);
        AppHaptics.medium();
      });
    } else {
      // 非图钉区域：长按触发拖拽
      _longPressTimer = Timer(_tapDelay, () {
        _startDragging(event.position);
      });
    }
  }

  /// 处理指针移动事件
  void _handlePointerMove(PointerMoveEvent event, {bool isPin = false}) {
    if (_pointerDownPosition == null) return;
    final delta = event.localPosition - _pointerDownPosition!;
    final slop = _pointerStartedOnPin ? _pinTouchSlop : _touchSlop;

    if (delta.distance > slop) {
      _hasMoved = true;
      _tapTimer?.cancel();
      if (!_isDragging && !_isConnecting) {
        _longPressTimer?.cancel();
      }
    }

    if (_isConnecting) {
      widget.onPinLongPressMove?.call(event.position);
    } else if (_isDragging) {
      widget.onDragUpdate?.call(event.position);
    }
  }

  /// 处理指针抬起事件
  void _handlePointerUp(PointerUpEvent event, {bool isPin = false}) {
    _longPressTimer?.cancel();
    _setPressed(false);
    widget.onPointerUp?.call();

    if (_isConnecting) {
      widget.onPinLongPressEnd?.call();
      AppHaptics.dragEnd();
    } else if (_isDragging) {
      widget.onDragEnd?.call();
      AppHaptics.dragEnd();
      setState(() {
        // 拖拽结束，恢复缩放
        _pressedScaleAnimation = Tween<double>(begin: 1.0, end: WallConstants.pressScale).animate(
          CurvedAnimation(
            parent: _pressedAnimationController,
            curve: Curves.easeInOut,
          ),
        );
      });
    } else if (!_hasMoved) {
      // 未移动：进入点击判定（区分单击和双击）
      _handleTap(event.position);
    }

    _pointerDownPosition = null;
    _isConnecting = false;
    _isDragging = false;
    _pointerStartedOnPin = false;
  }

  /// 处理指针取消事件
  void _handlePointerCancel(PointerCancelEvent event) {
    _longPressTimer?.cancel();
    _tapTimer?.cancel();
    _setPressed(false);
    widget.onPointerUp?.call();

    if (_isConnecting) {
      widget.onPinLongPressEnd?.call();
      _isConnecting = false;
    } else if (_isDragging) {
      widget.onDragEnd?.call();
      setState(() {
        _isDragging = false;
      });
    } else {
      _isDragging = false;
      _isConnecting = false;
    }
    _pointerStartedOnPin = false;
    _pointerDownPosition = null;
  }

  /// 进入拖拽模式
  void _startDragging(Offset position) {
    setState(() {
      _isDragging = true;
    });
    // 拖拽时缩放到 1.04，模拟"抬起"感
    _pressedScaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(
        parent: _pressedAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _pressedAnimationController.forward();
    widget.onDragStart?.call(position);
    AppHaptics.dragStart();
  }

  /// 处理点击判定 —— 区分单击和双击
  ///
  /// 使用 [GestureCoordinator.shouldRecognizeDoubleTap] 判断是否为双击：
  /// - 双击：立即触发 [onDoubleTap]
  /// - 单击：延迟 250ms 触发（等待双击窗口期结束），避免误判
  void _handleTap(Offset position) {
    _tapTimer?.cancel();

    if (_gestureCoordinator.shouldRecognizeDoubleTap(position)) {
      widget.onDoubleTap?.call();
      AppHaptics.medium();
    } else {
      _tapTimer = Timer(_tapDelay, () {
        widget.onTap?.call();
        AppHaptics.light();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根据照片风格决定边框尺寸和背景色
    final isVintage = widget.photo.photoStyle == PhotoStyle.vintage;
    final bgColor = isVintage ? AppColors.agedPaper : Colors.white;

    // 拖拽状态的阴影（更深更远）
    final dragShadow = _isDragging
        ? [
            AppShadows.cardDrag,
          ]
        : null;

    // 主要选中状态的装饰
    final highlightDecoration = widget.isPrimary
        ? BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.redThread.withValues(alpha: 0.5),
              width: 2.5,
            ),
            boxShadow: dragShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
          )
        : widget.isHighlighted
            ? BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.tagOrange.withValues(alpha: 0.7),
                  width: 2,
                ),
                boxShadow: dragShadow ??
                    [
                      BoxShadow(
                        color: AppColors.tagOrange.withValues(alpha: 0.18),
                        blurRadius: 10,
                        spreadRadius: 1.5,
                      ),
                    ],
              )
            : null;

    // 连线目标状态的图钉装饰（带脉冲动画）
    final pulseValue = _targetPulseAnimation.value;
    final pinShadow = widget.isConnectingTarget
        ? [
            BoxShadow(
              color: AppColors.redThread
                  .withValues(alpha: 0.3 + pulseValue * 0.3),
              blurRadius: 6 + pulseValue * 4,
              spreadRadius: 1 + pulseValue * 2,
            ),
          ]
        : null;

    final topInset = isVintage
        ? WallConstants.photoInsetTopVintage
        : WallConstants.photoInsetTopPolaroid;
    final sideInset = isVintage
        ? WallConstants.photoInsetSideVintage
        : WallConstants.photoInsetSidePolaroid;
    final bottomInset = isVintage
        ? WallConstants.photoInsetBottomVintage
        : WallConstants.photoInsetBottomPolaroid;
    final cornerRadius = isVintage
        ? WallConstants.photoCornerRadiusVintage
        : WallConstants.photoCornerRadiusPolaroid;

    return FadeTransition(
      opacity: _entranceController,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
        ),
        child: Transform.rotate(
      angle: widget.photo.rotation * pi / 180,
      child: AnimatedBuilder(
        animation: _pressedScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pressedScaleAnimation.value,
            child: child,
          );
        },
        child: SizedBox(
          width: widget.photo.width,
          height: widget.photo.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
            Semantics(
              label: '照片${widget.photo.caption != null ? ': ${widget.photo.caption}' : ''}',
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
                child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final glowAlpha = widget.isPrimary
                      ? 0.08 + _glowController.value * 0.12
                      : 0.15;
                  final baseDecoration = highlightDecoration ??
                      BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(cornerRadius),
                        border: Border.all(
                          color: Colors.black
                              .withValues(alpha: isVintage ? 0.1 : 0.06),
                          width: isVintage ? 0.5 : 0.3,
                        ),
                        boxShadow: dragShadow ??
                            [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isVintage ? 0.26 : 0.22),
                                offset: const Offset(1, 3),
                                blurRadius: 6,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                offset: const Offset(2, 8),
                                blurRadius: 18,
                                spreadRadius: -3,
                              ),
                            ],
                      );
                  final glowDecoration = widget.isPrimary && highlightDecoration != null
                      ? baseDecoration.copyWith(
                          boxShadow: [
                            ...baseDecoration.boxShadow ?? [],
                            BoxShadow(
                              color: AppColors.redThread.withValues(alpha: glowAlpha),
                              offset: const Offset(0, 3),
                              blurRadius: 14,
                              spreadRadius: 3,
                            ),
                          ],
                        )
                      : baseDecoration;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    decoration: glowDecoration,
                    child: child,
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 图片区域
                    Positioned(
                      top: topInset,
                      left: sideInset,
                      right: sideInset,
                      bottom: bottomInset,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isVintage ? 2 : 1),
                        child: File(widget.photo.imagePath).isAbsolute
                            ? Image.file(
                                File(widget.photo.imagePath),
                                fit: BoxFit.cover,
                                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded || frame != null) return child;
                                  return _buildImagePlaceholder();
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder();
                                },
                              )
                            : _buildImagePlaceholder(),
                      ),
                    ),
                    // 手写风格标题
                    Positioned(
                      bottom: isVintage
                          ? WallConstants.photoCaptionBottomVintage
                          : WallConstants.photoCaptionBottomPolaroid,
                      left: sideInset,
                      right: sideInset,
                      child: widget.photo.caption != null
                          ? Text(
                              widget.photo.caption!,
                              style: TextStyle(
                                fontFamily: AppTypography.caveat,
                                fontFamilyFallback: const [AppTypography.lxgwWenKai],
                                fontSize: isVintage
                                    ? WallConstants.photoCaptionFontSizeVintage
                                    : WallConstants.photoCaptionFontSizePolaroid,
                                color: AppColors.inkBlack
                                    .withValues(alpha: isVintage ? 0.55 : 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            ),
            ),
            // 可交互图钉：独立 Listener，位于照片顶部中央，支持长按连线
            Positioned(
              top: 0,
              left: widget.photo.width / 2 - WallConstants.pushpinCenterOffset,
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
                  onPointerCancel: (event) {
                    _pinPressed.value = false;
                    _handlePointerCancel(event);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: WallConstants.pushpinHitArea,
                    height: WallConstants.pushpinHitArea,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: pinShadow,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _pinPressed,
                          builder: (context, pressed, _) => Pushpin(
                            color: AppColors.pinRed,
                            isPressed: pressed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
        ),
      ),
    );
  }

  /// 构建图片加载失败占位符
  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.warmGray.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: AppColors.warmGray.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
