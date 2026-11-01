
import 'package:flutter/material.dart';

import '../../models/card_model.dart';
import '../../theme/wall_constants.dart';

/// 拖拽会话（不可变）
///
/// 封装一次拖拽操作的起始状态：被拖拽的卡片 ID、手指起始位置、
/// 卡片起始位置。这三个字段总是一起设置，提取为不可变对象
/// 确保状态一致性。
class DragSession {
  final int cardId;
  final Offset dragStart;
  final Offset cardStartPos;

  const DragSession({
    required this.cardId,
    required this.dragStart,
    required this.cardStartPos,
  });
}

/// 拖拽处理器
///
/// 管理卡片拖拽状态，实现边界阻尼（越界弹性效果）和回弹动画。
/// 当用户拖拽卡片超出画布边界时，不是硬性阻止，而是施加阻尼效果
/// 使卡片移动变慢，松手后自动弹回合法区域，提供自然的物理手感。
///
/// 使用 [DragSession] 封装拖拽起始状态，确保相关字段的一致性。
class DragHandler {
  /// 当前拖拽会话，null 表示未在拖拽
  DragSession? _session;

  /// 卡片的实际位置（画布坐标系），未经阻尼处理。
  /// 该值记录了卡片"应该"在的位置，用于判断是否越界
  /// 以及计算回弹动画的目标位置。
  Offset _actualPos = Offset.zero;

  /// 当前拖拽卡片的实际宽高，由 onDragStart 传入
  double _cardWidth = WallConstants.cardWidth;
  double _cardHeight = WallConstants.cardHeight;

  /// 边界外缓冲区域的宽度（画布坐标像素）。
  ///
  /// 该值定义了卡片可以超出画布边界的最大距离。
  /// 在此范围内，阻尼效果使卡片移动逐渐减速；
  /// 超出此范围后，卡片位置被完全钳制，不再继续移动。
  ///
  /// 100px 约为卡片宽度的 1/4，提供足够的越界可视反馈，
  /// 同时不会让卡片完全脱离画布导致用户找不到。
  static const double _boundaryMargin = 100.0;

  /// 阻尼系数，控制越界时移动速度的衰减程度。
  ///
  /// 值越小，越界时的阻尼效果越强（移动越慢）。
  /// 0.15 意味着越界距离的约 15% 会被实际反映为位移，
  /// 其余部分被阻尼"吸收"，产生明显的减速效果。
  ///
  /// 该值经过调优，在"能感受到越界"和"不会拖太远"之间取得平衡。
  /// 如果设为 1.0 则无阻尼（线性映射），设为 0 则完全阻止越界。
  static const double _overscrollFactor = 0.15;

  /// 当前是否正在拖拽卡片
  bool get isDragging => _session != null;

  /// 当前正在拖拽的卡片 ID，null 表示未在拖拽
  int? get draggingCardId => _session?.cardId;

  /// 拖拽起始时卡片的左上角位置（画布坐标系）
  Offset get cardStartPos => _session?.cardStartPos ?? Offset.zero;

  /// 拖拽起始时手指的全局坐标（屏幕坐标系）
  Offset get dragStart => _session?.dragStart ?? Offset.zero;

  /// 画布左边界（卡片左边缘允许的最小 X 坐标）
  double get boundaryLeft => _boundaryMargin;

  /// 画布上边界（卡片上边缘允许的最小 Y 坐标）
  double get boundaryTop => _boundaryMargin;

  /// 画布右边界（卡片右边缘允许的最大 X 坐标）
  /// = 画布宽度 - 卡片宽度 - 边距
  double get boundaryRight =>
      WallConstants.canvasWidth - _cardWidth - _boundaryMargin;

  /// 画布下边界（卡片下边缘允许的最大 Y 坐标）
  /// = 画布高度 - 卡片高度 - 边距
  double get boundaryBottom =>
      WallConstants.canvasHeight - _cardHeight - _boundaryMargin;

  /// 获取卡片的实际位置（未经阻尼处理）
  Offset get actualPosition => _actualPos;

  /// 开始拖拽
  ///
  /// 记录拖拽起始状态：被拖拽卡片的 ID、手指起始位置、卡片起始位置。
  /// 实际位置初始化为卡片起始位置，随拖拽更新而变化。
  void onDragStart(int cardId, Offset globalPosition, ClueCard card) {
    _session = DragSession(
      cardId: cardId,
      dragStart: globalPosition,
      cardStartPos: Offset(card.x, card.y),
    );
    _actualPos = Offset(card.x, card.y);
    _cardWidth = card.width;
    _cardHeight = card.height;
  }

  /// 拖拽更新
  ///
  /// 根据手指位移量计算卡片的新位置，并应用边界阻尼效果。
  ///
  /// 算法步骤：
  /// 1. 计算手指位移量 = 当前全局位置 - 起始全局位置
  /// 2. 除以 canvasScale 将屏幕像素位移转换为画布坐标位移
  ///    （缩放级别越大，同样的屏幕位移对应更小的画布位移）
  /// 3. 实际位置 = 卡片起始位置 + 画布位移量
  /// 4. 对实际位置分别施加 X/Y 方向的阻尼效果
  /// 5. 返回阻尼后的位置用于 UI 渲染
  Offset? onDragUpdate(Offset globalPosition, double canvasScale) {
    final session = _session;
    if (session == null) return null;

    // 手指在画布坐标系中的位移量
    final delta = (globalPosition - session.dragStart) / canvasScale;

    // 计算卡片的实际位置（无阻尼）
    _actualPos = session.cardStartPos + delta;

    // 对 X/Y 方向分别施加阻尼
    final dampedX = _applyDamping(_actualPos.dx, boundaryLeft, boundaryRight);
    final dampedY = _applyDamping(_actualPos.dy, boundaryTop, boundaryBottom);

    return Offset(dampedX, dampedY);
  }

  /// 对单个轴施加阻尼效果
  ///
  /// 阻尼逻辑分为三个区域：
  ///
  /// 1. 合法区域 [min, max]：无阻尼，直接返回原值
  ///
  /// 2. 越界但未超出缓冲区（overscroll ≤ _boundaryMargin）：
  ///    施加阻尼，越界距离通过 [_applyOverscrollDamping] 衰减
  ///    例如：越界 50px → 实际位移约 50 × 0.15 × (1 + 50/100) ≈ 11.25px
  ///
  /// 3. 超出缓冲区（overscroll > _boundaryMargin）：
  ///    位置被钳制到缓冲区边界对应的阻尼值，不再继续移动
  ///    这防止卡片被拖到画布外太远的地方
  ///
  /// 阻尼是渐变的：越靠近边界外缘，阻尼越强，移动越慢，
  /// 产生类似"推橡皮筋"的物理手感。
  double _applyDamping(double value, double min, double max) {
    // 在合法范围内，无阻尼
    if (value >= min && value <= max) {
      return value;
    }

    // 低于下边界
    if (value < min) {
      final overscroll = min - value;
      if (overscroll <= _boundaryMargin) {
        // 越界但未超出缓冲区：施加阻尼
        return min - _applyOverscrollDamping(overscroll);
      }
      // 超出缓冲区：钳制到缓冲区边界的阻尼值
      return min - _boundaryMargin + _applyOverscrollDamping(_boundaryMargin);
    }

    // 高于上边界（逻辑与下边界对称）
    final overscroll = value - max;
    if (overscroll <= _boundaryMargin) {
      return max + _applyOverscrollDamping(overscroll);
    }
    return max + _boundaryMargin - _applyOverscrollDamping(_boundaryMargin);
  }

  /// 越界阻尼函数
  ///
  /// 将原始越界距离转换为阻尼后的实际位移量。
  ///
  /// 公式：damped = overscroll × _overscrollFactor × (1 + overscroll / _boundaryMargin)
  ///
  /// 该公式是一个二次递增函数，具有以下特性：
  /// - overscroll = 0 时，damped = 0（刚越界时无位移）
  /// - 随着越界距离增大，位移增速加快（但始终远小于线性增长）
  /// - 二次项 (overscroll² / _boundaryMargin) 使阻尼曲线平滑，
  ///   避免在边界处出现速度突变
  ///
  /// 对比线性阻尼（damped = overscroll × factor）：
  /// - 线性阻尼在边界处有明显的速度跳变（从全速突然变为 factor 倍速）
  /// - 本公式的 (1 + overscroll / _boundaryMargin) 项使速度在边界处
  ///   从全速平滑过渡到减速，提供更自然的物理手感
  ///
  /// 示例（_overscrollFactor = 0.15, _boundaryMargin = 100）：
  /// - overscroll = 10px → damped = 10 × 0.15 × 1.1 = 1.65px
  /// - overscroll = 50px → damped = 50 × 0.15 × 1.5 = 11.25px
  /// - overscroll = 100px → damped = 100 × 0.15 × 2.0 = 30px
  double _applyOverscrollDamping(double overscroll) {
    if (overscroll <= 0) return 0;
    return overscroll * _overscrollFactor * (1 + overscroll / _boundaryMargin);
  }

  /// 判断卡片实际位置是否超出边界足够远
  ///
  /// 用于决定松手后是否需要触发回弹动画。
  /// 阈值设为 _boundaryMargin × 0.5（50px），而非完整的 _boundaryMargin，
  /// 是因为用户只需拖出边界的一半距离就应触发回弹，
  /// 而不必拖到缓冲区的极限才响应。
  bool get isBeyondBoundary {
    return _actualPos.dx < boundaryLeft - _boundaryMargin * 0.5 ||
        _actualPos.dx > boundaryRight + _boundaryMargin * 0.5 ||
        _actualPos.dy < boundaryTop - _boundaryMargin * 0.5 ||
        _actualPos.dy > boundaryBottom + _boundaryMargin * 0.5;
  }

  /// 计算回弹动画的目标位置
  ///
  /// 将卡片的实际位置钳制到合法边界内，作为回弹动画的终点。
  /// 回弹动画由上层调用者通过 AnimationController 驱动，
  /// 从当前阻尼位置平滑过渡到此目标位置。
  ///
  /// 使用 clamp 确保目标位置严格在 [boundaryLeft, boundaryRight] 和
  /// [boundaryTop, boundaryBottom] 范围内。
  Offset getSpringBackTarget() {
    final targetX = _actualPos.dx.clamp(boundaryLeft, boundaryRight);
    final targetY = _actualPos.dy.clamp(boundaryTop, boundaryBottom);
    return Offset(targetX, targetY);
  }

  /// 结束拖拽
  ///
  /// 清除拖拽会话，返回被拖拽卡片的 ID 供上层使用。
  /// 注意：不重置 _actualPos，因为回弹动画可能仍在使用该值。
  int? onDragEnd() {
    final id = _session?.cardId;
    _session = null;
    return id;
  }

  /// 完全重置所有拖拽状态
  ///
  /// 在回弹动画完成或需要强制取消拖拽时调用，
  /// 将所有状态恢复到初始值。
  void reset() {
    _session = null;
    _actualPos = Offset.zero;
  }
}
