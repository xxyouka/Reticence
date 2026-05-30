import 'package:flutter/material.dart';

import '../../models/photo_card_model.dart';
import '../../theme/wall_constants.dart';

/// 照片拖拽会话（不可变）
///
/// 封装一次照片拖拽操作的起始状态：被拖拽的照片 ID、手指起始位置、
/// 照片起始位置。
class PhotoDragSession {
  final int photoId;
  final Offset dragStart;
  final Offset photoStartPos;

  const PhotoDragSession({
    required this.photoId,
    required this.dragStart,
    required this.photoStartPos,
  });
}

/// 照片拖拽处理器
///
/// 管理照片卡片的拖拽状态，与 [DragHandler]（卡片拖拽）对称。
/// 使用 [PhotoDragSession] 封装拖拽起始状态，确保相关字段的一致性。
///
/// 实现边界阻尼（越界弹性效果）和回弹动画，与 DragHandler 行为一致。
/// 当用户拖拽照片超出画布边界时，施加阻尼效果使移动变慢，
/// 松手后自动弹回合法区域，提供自然的物理手感。
class PhotoDragHandler {
  PhotoDragSession? _session;

  /// 照片的实际位置（画布坐标系），未经阻尼处理。
  Offset _actualPos = Offset.zero;

  /// 当前拖拽照片的实际宽高，由 onDragStart 传入
  double _photoWidth = WallConstants.photoCardWidth;
  double _photoHeight = WallConstants.photoCardHeight;

  /// 边界外缓冲区域的宽度（画布坐标像素）。
  ///
  /// 该值定义了照片可以超出画布边界的最大距离。
  /// 在此范围内，阻尼效果使照片移动逐渐减速；
  /// 超出此范围后，照片位置被完全钳制，不再继续移动。
  static const double _boundaryMargin = 100.0;

  /// 阻尼系数，控制越界时移动速度的衰减程度。
  ///
  /// 值越小，越界时的阻尼效果越强（移动越慢）。
  /// 0.15 意味着越界距离的约 15% 会被实际反映为位移，
  /// 其余部分被阻尼"吸收"，产生明显的减速效果。
  static const double _overscrollFactor = 0.15;

  /// 当前是否正在拖拽照片
  bool get isDragging => _session != null;

  /// 当前正在拖拽的照片 ID
  int? get draggingPhotoId => _session?.photoId;

  /// 拖拽起始时照片的左上角位置（画布坐标系）
  Offset get photoStartPos => _session?.photoStartPos ?? Offset.zero;

  /// 照片的实际位置（未经阻尼处理）
  Offset get actualPosition => _actualPos;

  /// 画布左边界（照片左边缘允许的最小 X 坐标）
  double get boundaryLeft => _boundaryMargin;

  /// 画布上边界（照片上边缘允许的最小 Y 坐标）
  double get boundaryTop => _boundaryMargin;

  /// 画布右边界（照片右边缘允许的最大 X 坐标）
  double get boundaryRight =>
      WallConstants.canvasWidth - _photoWidth - _boundaryMargin;

  /// 画布下边界（照片下边缘允许的最大 Y 坐标）
  double get boundaryBottom =>
      WallConstants.canvasHeight - _photoHeight - _boundaryMargin;

  /// 开始拖拽
  void onDragStart(int photoId, Offset globalPosition, PhotoCard photo) {
    _session = PhotoDragSession(
      photoId: photoId,
      dragStart: globalPosition,
      photoStartPos: Offset(photo.x, photo.y),
    );
    _actualPos = Offset(photo.x, photo.y);
    _photoWidth = photo.width;
    _photoHeight = photo.height;
  }

  /// 拖拽更新
  ///
  /// 返回照片在画布坐标系中的新位置（经阻尼处理），由调用方写入 provider。
  Offset? onDragUpdate(Offset globalPosition, double canvasScale) {
    final session = _session;
    if (session == null) return null;

    // 手指在画布坐标系中的位移量
    final delta = (globalPosition - session.dragStart) / canvasScale;

    // 计算照片的实际位置（无阻尼）
    _actualPos = session.photoStartPos + delta;

    // 对 X/Y 方向分别施加阻尼
    final dampedX = _applyDamping(_actualPos.dx, boundaryLeft, boundaryRight);
    final dampedY = _applyDamping(_actualPos.dy, boundaryTop, boundaryBottom);

    return Offset(dampedX, dampedY);
  }

  /// 对单个轴施加阻尼效果
  ///
  /// 阻尼逻辑分为三个区域：
  /// 1. 合法区域 [min, max]：无阻尼，直接返回原值
  /// 2. 越界但未超出缓冲区：施加阻尼，越界距离通过衰减
  /// 3. 超出缓冲区：位置被钳制到缓冲区边界对应的阻尼值
  double _applyDamping(double value, double min, double max) {
    if (value >= min && value <= max) {
      return value;
    }

    if (value < min) {
      final overscroll = min - value;
      if (overscroll <= _boundaryMargin) {
        return min - _applyOverscrollDamping(overscroll);
      }
      return min - _boundaryMargin + _applyOverscrollDamping(_boundaryMargin);
    }

    final overscroll = value - max;
    if (overscroll <= _boundaryMargin) {
      return max + _applyOverscrollDamping(overscroll);
    }
    return max + _boundaryMargin - _applyOverscrollDamping(_boundaryMargin);
  }

  /// 越界阻尼函数
  ///
  /// 将原始越界距离转换为阻尼后的实际位移量。
  /// 公式：damped = overscroll × _overscrollFactor × (1 + overscroll / _boundaryMargin)
  double _applyOverscrollDamping(double overscroll) {
    if (overscroll <= 0) return 0;
    return overscroll * _overscrollFactor * (1 + overscroll / _boundaryMargin);
  }

  /// 判断照片实际位置是否超出边界足够远
  ///
  /// 用于决定松手后是否需要触发回弹动画。
  bool get isBeyondBoundary {
    return _actualPos.dx < boundaryLeft - _boundaryMargin * 0.5 ||
        _actualPos.dx > boundaryRight + _boundaryMargin * 0.5 ||
        _actualPos.dy < boundaryTop - _boundaryMargin * 0.5 ||
        _actualPos.dy > boundaryBottom + _boundaryMargin * 0.5;
  }

  /// 计算回弹动画的目标位置
  ///
  /// 将照片的实际位置钳制到合法边界内，作为回弹动画的终点。
  Offset getSpringBackTarget() {
    final targetX = _actualPos.dx.clamp(boundaryLeft, boundaryRight);
    final targetY = _actualPos.dy.clamp(boundaryTop, boundaryBottom);
    return Offset(targetX, targetY);
  }

  /// 结束拖拽
  ///
  /// 清除拖拽会话，返回被拖拽照片的 ID 供上层使用。
  int? onDragEnd() {
    final id = _session?.photoId;
    _session = null;
    return id;
  }

  /// 完全重置所有拖拽状态
  void reset() {
    _session = null;
    _actualPos = Offset.zero;
  }
}
