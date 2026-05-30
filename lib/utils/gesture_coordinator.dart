/// 手势协调器 —— 侦探板上的多意图手势识别
///
/// 本文件实现了 Reticence 应用中软木板画布的手势状态机，
/// 用于区分用户在卡片上的多种操作意图：
///
/// - **单击**：选中卡片
/// - **双击**：编辑卡片
/// - **长按**：从图钉开始拉出红线（连接模式）
/// - **拖拽**：移动卡片位置
/// - **连接拖拽**：从图钉拖出红线到另一张卡片
///
/// 状态机核心流程：
/// ```
/// idle ──→ possibleTap ──→ (抬起) ──→ 识别为单击/双击
///   │           │
///   │           └──→ (移动超 slop) ──→ dragging
///   │
///   └──→ possibleLongPress ──→ (移动超 slop) ──→ connecting
///   └──→ possibleDoubleTap ──→ (超时/距离超限) ──→ 识别为双击
/// ```
///
/// 设计挑战：在同一个触摸区域上区分"点击"、"长按"和"拖拽"
/// 三种意图，需要通过移动距离（touch slop）和时间（timeout）
/// 两个维度来消歧。本协调器采用"延迟决策"策略——
/// 手指按下时不立即判断意图，而是进入"可能"状态，
/// 根据后续的移动和抬起事件来最终确定。
library;

import 'package:flutter/material.dart';

/// 手势阶段枚举——状态机的所有可能状态
///
/// 每个状态代表手势识别的一个阶段：
/// - idle：无手势进行中，等待新的触摸事件
/// - possibleTap：手指按下，可能是一次单击
/// - possibleDoubleTap：已识别首次点击，等待可能的第二次点击
/// - possibleLongPress：手指按在图钉上，可能是长按拉线
/// - dragging：已确认拖拽意图，正在移动卡片
/// - connecting：已确认连接意图，正在拉出红线
enum GesturePhase {
  idle,
  possibleTap,
  possibleDoubleTap,
  possibleLongPress,
  dragging,
  connecting,
}

class GestureCoordinator {
  /// 当前手势阶段
  GesturePhase _phase = GesturePhase.idle;

  /// 上一次点击的时间，用于双击检测的时间窗口判断
  DateTime? _lastTapTime;

  /// 上一次点击的位置，用于双击检测的距离判断
  /// （两次点击位置太远则不算双击）
  Offset? _lastTapPosition;

  /// 当前活跃的卡片 ID，标识正在操作的卡片
  int? _activeCardId;

  /// 是否正在拖拽卡片
  bool _isDragging = false;

  /// 是否正在拉出红线连接
  bool _isConnecting = false;

  // ============================================================
  // 阈值常量（Threshold Constants）
  //
  // 这些阈值是手势消歧的关键参数，需要平衡：
  // - 太小：轻微手抖就会误判为拖拽，难以触发点击/长按
  // - 太大：需要明显移动才能触发拖拽，响应迟钝
  // ============================================================

  /// 双击超时时间（毫秒）
  ///
  /// 280ms 是双击检测的经典阈值，源自各平台的人机交互指南：
  /// - iOS：约 250-300ms
  /// - Android：约 300ms（ViewConfiguration.getDoubleTapTimeout）
  /// - Material Design：约 300ms
  ///
  /// 两次点击间隔超过此值则视为两次独立单击。
  static const int doubleTapTimeout = 280;

  /// 长按超时时间（毫秒）
  ///
  /// 300ms 是长按识别的标准阈值。手指按住超过此时间
  /// 即识别为长按意图（从图钉开始拉线）。
  /// 注意：本协调器不直接计时，此常量供外部计时器使用。
  static const int longPressTimeout = 300;

  /// 手势状态机触摸移动阈值（像素）
  ///
  /// 手指移动距离超过此值才识别为拖拽意图。
  /// 12px 略小于 Android 默认的 touchSlop（约 8dp 逻辑像素），
  /// 因为在软木板这种自由画布上，用户期望更灵敏的拖拽响应。
  /// 同时也足够大以过滤掉手指按下时的自然抖动。
  ///
  /// 注意：与 [WallConstants.touchSlop]（18px，用于卡片拖拽判定）不同，
  /// 此值用于手势状态机内部的意图消歧。
  static const double gestureTouchSlop = 12.0;

  /// 双击距离阈值（像素）
  ///
  /// 两次点击的位置距离小于此值才视为双击。
  /// 40px 约等于 8-10mm 的物理距离，允许手指在
  /// 第二次点击时有轻微的位置偏移，同时排除
  /// 在不同位置快速点击的误判。
  static const double doubleTapDistance = 40.0;

  // ============================================================
  // 状态访问器（State Getters）
  // ============================================================

  /// 当前手势阶段
  GesturePhase get phase => _phase;

  /// 是否正在拖拽
  bool get isDragging => _isDragging;

  /// 是否正在连接
  bool get isConnecting => _isConnecting;

  /// 当前活跃的卡片 ID
  int? get activeCardId => _activeCardId;

  // ============================================================
  // 手势事件处理方法（Gesture Event Handlers）
  //
  // 以下方法由外部手势识别器调用，按照触摸事件的
  // 生命周期顺序排列：Down → Move → Up/Cancel
  // ============================================================

  /// 卡片区域手指按下
  ///
  /// 当手指按在卡片的主体区域（非图钉）时调用。
  /// 进入 possibleTap 状态，等待后续事件判断意图。
  ///
  /// 返回 true 表示手势被接受，false 表示被拒绝
  /// （当前正在连接中，不接受新的卡片操作）。
  bool onCardPointerDown(int cardId, Offset position) {
    if (_isConnecting) return false; // 连接进行中，拒绝新操作
    _phase = GesturePhase.possibleTap;
    _activeCardId = cardId;
    return true;
  }

  /// 图钉区域手指按下
  ///
  /// 当手指按在卡片的图钉区域时调用。
  /// 进入 possibleLongPress 状态，因为图钉是
  /// 拉出红线的起始点，需要长按来区分"点击图钉"
  /// 和"从图钉拉线"两种意图。
  ///
  /// 返回 true 表示手势被接受，false 表示被拒绝。
  bool onPinPointerDown(int cardId, Offset position) {
    if (_isConnecting) return false; // 连接进行中，拒绝新操作
    _phase = GesturePhase.possibleLongPress;
    _activeCardId = cardId;
    return true;
  }

  /// 手指抬起
  ///
  /// 当手指从屏幕上抬起时调用。如果此时仍处于
  /// possibleTap 或 possibleLongPress 状态，
  /// 说明手指没有移动超过 slop 阈值，应识别为点击。
  ///
  /// 返回 true 表示这是一个有效的点击/长按抬起，
  /// 调用方应进一步判断是单击还是双击。
  bool onPointerUp(Offset position) {
    final wasPossibleTap = _phase == GesturePhase.possibleTap;
    final wasPossibleLongPress = _phase == GesturePhase.possibleLongPress;

    _phase = GesturePhase.idle;
    _isDragging = false;
    return wasPossibleTap || wasPossibleLongPress;
  }

  /// 手指移动
  ///
  /// 当手指在屏幕上移动时调用。根据移动距离和当前状态
  /// 判断手势意图：
  ///
  /// 1. 如果正在连接中（_isConnecting），直接返回 true
  ///    继续处理连接拖拽
  /// 2. 如果处于 possibleLongPress 且是图钉手势，
  ///    立即进入连接模式（长按图钉后移动 = 拉线）
  /// 3. 如果移动距离超过 touchSlop：
  ///    - 图钉手势 → 进入连接模式
  ///    - 卡片手势 → 进入拖拽模式
  /// 4. 否则保持当前状态，继续等待
  ///
  /// [delta] 是相对于上一次移动事件的位移量
  /// [isPinGesture] 是否是图钉区域的手势
  bool onPointerMove(Offset delta, {required bool isPinGesture}) {
    if (_isConnecting) return true; // 连接中，持续处理

    // 长按图钉后的任何移动都视为拉线意图
    if (_phase == GesturePhase.possibleLongPress && isPinGesture) {
      _phase = GesturePhase.connecting;
      _isConnecting = true;
      return true;
    }

    // 移动距离超过阈值，消歧为拖拽或连接
    final distance = delta.distance;
    if (distance > gestureTouchSlop && !_isDragging) {
      if (isPinGesture) {
        // 图钉手势 → 拉出红线
        _phase = GesturePhase.connecting;
        _isConnecting = true;
      } else {
        // 卡片手势 → 移动卡片
        _phase = GesturePhase.dragging;
        _isDragging = true;
      }
      return true;
    }

    // 未超过阈值或已在拖拽/连接中
    return _isDragging || _isConnecting;
  }

  /// 手势取消
  ///
  /// 当系统取消触摸事件时调用（如来电打断、多指冲突等），
  /// 直接重置所有状态。
  void onPointerCancel() {
    reset();
  }

  // ============================================================
  // 双击检测方法（Double Tap Detection）
  //
  // 双击检测需要同时满足时间和距离两个条件：
  // - 时间：两次点击间隔 < doubleTapTimeout (280ms)
  // - 距离：两次点击位置距离 < doubleTapDistance (40px)
  //
  // shouldRecognizeTap 和 shouldRecognizeDoubleTap
  // 是互补的两个方法，调用方根据需要选择使用。
  // ============================================================

  /// 判断是否应识别为单击
  ///
  /// 如果在双击超时窗口内检测到第二次点击，
  /// 则抑制单击识别（返回 false），等待双击判断。
  /// 否则记录本次点击的时间和位置，返回 true。
  ///
  /// 注意：此方法会在双击窗口内"吞掉"第一次单击，
  /// 以避免单击和双击同时触发。这是双击检测的经典策略。
  bool shouldRecognizeTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        _lastTapPosition != null &&
        now.difference(_lastTapTime!).inMilliseconds < doubleTapTimeout) {
      // 在双击窗口内，抑制单击，等待双击判断
      _lastTapTime = null;
      _lastTapPosition = null;
      return false;
    }

    _lastTapTime = now;
    return true;
  }

  /// 判断是否应识别为双击
  ///
  /// 同时满足以下条件才识别为双击：
  /// 1. 有上一次点击记录（_lastTapTime 和 _lastTapPosition 非空）
  /// 2. 两次点击间隔 < doubleTapTimeout (280ms)
  /// 3. 两次点击位置距离 < doubleTapDistance (40px)
  ///
  /// 识别为双击后清除记录（防止三次点击被误判为两次双击）。
  /// 否则更新记录为本次点击，作为下次判断的基准。
  bool shouldRecognizeDoubleTap(Offset position) {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        _lastTapPosition != null &&
        now.difference(_lastTapTime!).inMilliseconds < doubleTapTimeout &&
        (position - _lastTapPosition!).distance < doubleTapDistance) {
      // 双击条件满足，清除记录
      _lastTapTime = null;
      _lastTapPosition = null;
      return true;
    }

    // 不满足双击条件，更新为本次点击记录
    _lastTapTime = now;
    _lastTapPosition = position;
    return false;
  }

  // ============================================================
  // 状态重置方法（State Reset Methods）
  // ============================================================

  /// 结束连接操作
  ///
  /// 当红线连接完成或取消时调用，仅重置连接相关状态，
  /// 保留其他手势状态（如正在拖拽的卡片）。
  void endConnecting() {
    _isConnecting = false;
    _phase = GesturePhase.idle;
  }

  /// 完全重置所有手势状态
  ///
  /// 在手势取消、页面切换等需要彻底清理的场景调用。
  void reset() {
    _phase = GesturePhase.idle;
    _isDragging = false;
    _isConnecting = false;
    _activeCardId = null;
  }
}
