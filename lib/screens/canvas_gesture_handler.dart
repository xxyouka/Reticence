import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../providers/handlers/connection_handler.dart';
import '../theme/wall_constants.dart';
import '../utils/canvas_matrix.dart';

/// 画布手势处理器
///
/// 自定义手势识别器，替代 Flutter 内置的 InteractiveViewer，
/// 以实现更精细的手势控制。使用原始指针事件（Listener）而非
/// GestureDetector，因为需要同时处理多种手势且避免手势竞技场冲突。
///
/// 支持的手势类型：
/// - **平移（Pan）**：单指在画布空白区域拖拽，移动画布视口
/// - **双指缩放（Pinch Zoom）**：双指捏合/张开，以双指中心为焦点缩放
/// - **单击（Tap）**：短按画布空白区域，用于取消选中或点击红线
/// - **长按（Long Press）**：长按画布空白区域，拨动红线产生振动
/// - **双击（Double Tap）**：快速双击画布空白区域，自动适应所有内容
///
/// 手势冲突处理策略：
/// - 卡片上的触摸事件不触发画布手势
/// - 连线模式下的触摸事件用于更新连线位置
/// - 双指操作优先识别为缩放，取消长按计时器
/// - 单击和双击通过 300ms 延迟区分
class CanvasGestureHandler extends StatefulWidget {
  final TransformationController transformController;
  final AnimationController zoomController;
  final VoidCallback onInteractionEnd;
  final ConnectionHandler connectionHandler;
  final Function(Offset) updateConnecting;
  final bool Function() isCardInteracting;
  final Function(TapUpDetails) onTap;
  final VoidCallback onDoubleTap;
  final void Function(Offset globalPosition)? onLongPress;
  final void Function(bool)? onPinchStatusChanged;
  final Widget child;

  const CanvasGestureHandler({
    super.key,
    required this.transformController,
    required this.zoomController,
    required this.onInteractionEnd,
    required this.connectionHandler,
    required this.updateConnecting,
    required this.isCardInteracting,
    required this.onTap,
    required this.onDoubleTap,
    this.onLongPress,
    this.onPinchStatusChanged,
    required this.child,
  });

  @override
  State<CanvasGestureHandler> createState() => _CanvasGestureHandlerState();
}

/// 画布手势处理器的状态管理
///
/// 核心算法说明：
///
/// **指针追踪**：
/// 使用 [_activePointers] 计数器和 [_activePointerPositions] 映射表
/// 追踪所有活跃的触摸点。每个触摸点有唯一的 pointer ID，
/// 在 onPointerDown 时记录，onPointerUp/Cancel 时移除。
///
/// **双指缩放数学**：
/// 缩放以双指中心（焦点）为锚点进行，公式为：
/// ```
/// newScale = startScale × (currentSpan / startSpan)
/// newTranslation = focalPoint + actualRatio × (startTranslation - startFocal)
/// ```
/// 其中 span 是双指间距，focalPoint 是双指中心坐标。
/// 这样缩放时焦点位置保持不变，实现"捏哪里缩哪里"的效果。
///
/// **双击检测**：
/// 使用 [_tapCount] 计数器和 [_doubleTapTimer] 定时器实现：
/// - 第一次点击：计数器设为 1，启动 300ms 定时器
/// - 300ms 内第二次点击：计数器达到 2，立即触发双击回调
/// - 300ms 超时：触发单击回调，重置计数器
class _CanvasGestureHandlerState extends State<CanvasGestureHandler> {
  int _activePointers = 0;
  Offset? _lastFocalPoint;
  bool _isPinching = false;
  bool _isPanning = false;
  Offset? _pointerDownPosition;
  DateTime? _pointerDownTime;
  Timer? _doubleTapTimer;
  Timer? _longPressTimer;
  bool _hasMoved = false;
  int _tapCount = 0;
  bool _pointerDownOnCard = false;

  final Map<int, Offset> _activePointerPositions = {};
  double _lastPinchSpan = 0.0;
  Offset? _lastPinchFocal;

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: ClipRect(
        clipBehavior: Clip.hardEdge,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: AnimatedBuilder(
            animation: widget.transformController,
            builder: (context, child) {
              return Transform(
                transform: widget.transformController.value,
                child: child,
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    _activePointerPositions[event.pointer] = event.position;

    if (_activePointers == 1) {
      _pointerDownOnCard = widget.isCardInteracting();
      _lastFocalPoint = event.position;
      _isPinching = false;
      _isPanning = false;
      _pointerDownPosition = event.localPosition;
      _pointerDownTime = DateTime.now();
      _hasMoved = false;
      if (!_pointerDownOnCard &&
          !widget.connectionHandler.isConnecting &&
          widget.onLongPress != null) {
        _longPressTimer?.cancel();
        _longPressTimer = Timer(const Duration(milliseconds: WallConstants.canvasLongPressDelayMs), () {
          if (!_hasMoved &&
              _activePointers == 1 &&
              widget.onLongPress != null) {
            widget.onLongPress!(event.position);
          }
        });
      }
    } else if (_activePointers >= 2) {
      _longPressTimer?.cancel();
      widget.zoomController.stop();
      if (!_isPinching) {
        widget.onPinchStatusChanged?.call(true);
      }
      _isPinching = true;
      _isPanning = false;
      _lastPinchSpan = _computePinchSpan();
      _lastPinchFocal = _computeFocalCenter();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _activePointerPositions[event.pointer] = event.position;
    _longPressTimer?.cancel();

    if (widget.connectionHandler.isConnecting && !_pointerDownOnCard) {
      widget.updateConnecting(event.position);
      _hasMoved = true;
      return;
    }

    if (_isPinching) {
      _handlePinchZoom(event);
      return;
    }

    if (_activePointers >= 2 && !_pointerDownOnCard) {
      if (!_isPinching) {
        widget.onPinchStatusChanged?.call(true);
      }
      _isPinching = true;
      _isPanning = false;
      _lastPinchSpan = _computePinchSpan();
      _lastPinchFocal = _computeFocalCenter();
      return;
    }

    if (_pointerDownPosition != null) {
      final delta = event.localPosition - _pointerDownPosition!;
      if (delta.distance > 12.0) {
        _hasMoved = true;
      }
    }

    if (_pointerDownOnCard) return;

    if (_lastFocalPoint != null) {
      final delta = event.position - _lastFocalPoint!;
      if (!_isPanning && delta.distance > 16.0) {
        _isPanning = true;
        widget.zoomController.stop();
      }
      if (_isPanning) {
        final matrix = widget.transformController.value.clone();
        final scale = canvasMatrixScale(matrix);
        matrix.translateByVector3(
            Vector3(delta.dx / scale, delta.dy / scale, 0.0));
        widget.transformController.value = matrix;
        _lastFocalPoint = event.position;
      }
    }
  }

  double _computePinchSpan() {
    if (_activePointerPositions.length < 2) return 0.0;
    final positions = _activePointerPositions.values.toList();
    final a = positions[0];
    final b = positions[1];
    return (a - b).distance;
  }

  void _handlePinchZoom(PointerMoveEvent event) {
    final currentSpan = _computePinchSpan();
    final currentFocal = _computeFocalCenter();

    if (_lastPinchSpan <= 0.0 ||
        currentSpan <= 0.0 ||
        _lastPinchFocal == null) {
      _lastPinchSpan = currentSpan;
      _lastPinchFocal = currentFocal;
      return;
    }

    final matrix = widget.transformController.value.clone();
    final currentScale = canvasMatrixScale(matrix);
    final translation = matrix.getTranslation();

    final deltaScale = currentSpan / _lastPinchSpan;
    final newScale = (currentScale * deltaScale)
        .clamp(WallConstants.minScale, WallConstants.maxScale);

    final oldScreenTx = translation.x;
    final oldScreenTy = translation.y;

    final focalCanvasX = (_lastPinchFocal!.dx - oldScreenTx) / currentScale;
    final focalCanvasY = (_lastPinchFocal!.dy - oldScreenTy) / currentScale;

    final newScreenTx = currentFocal.dx - focalCanvasX * newScale;
    final newScreenTy = currentFocal.dy - focalCanvasY * newScale;

    final newMatrix = canvasMatrixFromScaleAndTranslation(
      scale: newScale,
      tx: newScreenTx,
      ty: newScreenTy,
    );

    widget.transformController.value = newMatrix;

    _lastPinchSpan = currentSpan;
    _lastPinchFocal = currentFocal;
  }

  Offset _computeFocalCenter() {
    if (_activePointerPositions.isEmpty) return Offset.zero;
    double x = 0, y = 0;
    for (final pos in _activePointerPositions.values) {
      x += pos.dx;
      y += pos.dy;
    }
    return Offset(
        x / _activePointerPositions.length, y / _activePointerPositions.length);
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 100);
    _activePointerPositions.remove(event.pointer);
    _longPressTimer?.cancel();

    if (_activePointers == 0) {
      final wasPinching = _isPinching;
      if (_isPanning || _isPinching) {
        widget.onInteractionEnd();
      } else if (!_hasMoved && !_pointerDownOnCard) {
        if (_pointerDownPosition != null && _pointerDownTime != null) {
          final now = DateTime.now();
          final delta = event.localPosition - _pointerDownPosition!;
          if (delta.distance < 10.0 &&
              now.difference(_pointerDownTime!).inMilliseconds < 350) {
            _handlePotentialDoubleTap(TapUpDetails(
              kind: PointerDeviceKind.touch,
              localPosition: event.localPosition,
              globalPosition: event.position,
            ));
          }
        }
      }

      if (wasPinching) {
        widget.onPinchStatusChanged?.call(false);
      }
      _lastFocalPoint = null;
      _isPinching = false;
      _isPanning = false;
      _pointerDownPosition = null;
      _pointerDownTime = null;
      _pointerDownOnCard = false;
      _lastPinchSpan = 0.0;
      _lastPinchFocal = null;
      _activePointerPositions.clear();
    } else if (_activePointers == 1) {
      if (_isPinching) {
        widget.onPinchStatusChanged?.call(false);
      }
      _isPinching = false;
      _isPanning = false;
      _lastPinchSpan = 0.0;
      _lastPinchFocal = null;
      _lastFocalPoint = _activePointerPositions.values.first;
      _hasMoved = true;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 100);
    _activePointerPositions.remove(event.pointer);
    _doubleTapTimer?.cancel();
    _longPressTimer?.cancel();
    if (_activePointers == 0) {
      if (_isPinching) {
        widget.onPinchStatusChanged?.call(false);
      }
      _lastFocalPoint = null;
      _isPinching = false;
      _isPanning = false;
      _pointerDownPosition = null;
      _pointerDownTime = null;
      _pointerDownOnCard = false;
      _lastPinchSpan = 0.0;
      _lastPinchFocal = null;
      _activePointerPositions.clear();
    } else if (_activePointers == 1) {
      if (_isPinching) {
        widget.onPinchStatusChanged?.call(false);
      }
      _isPinching = false;
      _isPanning = false;
      _lastPinchSpan = 0.0;
      _lastPinchFocal = null;
      if (_activePointerPositions.isNotEmpty) {
        _lastFocalPoint = _activePointerPositions.values.first;
      }
      _hasMoved = true;
    }
  }

  void _handlePotentialDoubleTap(TapUpDetails details) {
    _tapCount++;
    _doubleTapTimer?.cancel();

    if (_tapCount == 2) {
      widget.onDoubleTap();
      _tapCount = 0;
    } else {
      _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
        widget.onTap(details);
        _tapCount = 0;
      });
    }
  }
}
