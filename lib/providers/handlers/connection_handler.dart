
import 'package:flutter/material.dart';

import '../../models/card_model.dart';
import '../../models/photo_card_model.dart';
import '../../theme/wall_constants.dart';

/// 连接会话（不可变）
///
/// 封装一次连接操作的起始状态：起始元素的 ID 和位置。
/// [fromCardId] 和 [fromPhotoId] 互斥——恰好一个为非 null。
class ConnectionSession {
  final int? fromCardId;
  final int? fromPhotoId;
  final Offset fromPos;

  const ConnectionSession({
    this.fromCardId,
    this.fromPhotoId,
    required this.fromPos,
  }) : assert(fromCardId != null || fromPhotoId != null,
            'ConnectionSession 必须有一个起始端 ID');
}

/// 连接处理器
///
/// 管理用户从图钉拖拽创建红线连接的"正在连接"交互状态。
/// 当用户从某张卡片或照片的图钉开始拖拽时，进入连接模式，
/// 跟踪连接起点和当前拖拽位置，并在接近目标图钉时
/// 自动吸附，提供直观的连接创建体验。
///
/// 使用 [ConnectionSession] 封装连接起始状态，确保相关字段的一致性。
///
/// 交互流程：
/// 1. 用户长按/拖拽图钉 → [startConnecting] / [startConnectingFromPin] / [startConnectingFromPhoto]
/// 2. 用户拖动手指 → [updateConnecting] 更新连接线终点位置，并检测吸附
/// 3. 用户松开手指 → [finishConnecting] 判断是否成功连接到目标
/// 4. 无论成功与否 → [endConnecting] 清除连接状态
class ConnectionHandler {
  /// 当前连接会话，null 表示未处于连接模式
  ConnectionSession? _session;

  /// 连接线当前终点在画布坐标系中的位置
  Offset connectingCurrentPos = Offset.zero;

  /// 是否处于连接模式
  bool get isConnecting => _session != null;

  /// 连接起始卡片的 ID（当从卡片发起时非 null）
  int? get connectingFromCardId => _session?.fromCardId;

  /// 连接起始照片的 ID（当从照片发起时非 null）
  int? get connectingFromPhotoId => _session?.fromPhotoId;

  /// 连接起点在画布坐标系中的位置（图钉的中心点）
  Offset get connectingFromPos => _session?.fromPos ?? Offset.zero;

  /// 计算卡片图钉在画布坐标系中的中心位置
  ///
  /// 图钉位于卡片顶部水平居中位置：
  /// - X 坐标 = 卡片左边缘 + 卡片宽度的一半（水平居中）
  /// - Y 坐标 = 卡片上边缘 + pushpinCenterOffset（图钉在卡片顶部的固定偏移量）
  Offset pushpinPosition(ClueCard card) {
    return Offset(
      card.x + card.width / 2,
      card.y + WallConstants.pushpinCenterOffset,
    );
  }

  /// 计算照片图钉在画布坐标系中的中心位置
  ///
  /// 图钉位于照片顶部水平居中位置，44x44 触摸区域的中心。
  Offset photoPushpinPosition(PhotoCard photo) {
    return Offset(
      photo.x + photo.width / 2,
      photo.y + WallConstants.pushpinCenterOffset,
    );
  }

  /// 开始连接（从卡片内部触发）
  void startConnecting(int fromCardId, ClueCard card) {
    final pos = pushpinPosition(card);
    _session = ConnectionSession(fromCardId: fromCardId, fromPos: pos);
    connectingCurrentPos = pos;
  }

  /// 开始连接（从卡片图钉精确位置触发）
  void startConnectingFromPin(
      int fromCardId, Offset globalPos, ClueCard card, Matrix4 transform) {
    _session = ConnectionSession(
      fromCardId: fromCardId,
      fromPos: pushpinPosition(card),
    );
    connectingCurrentPos = MatrixUtils.transformPoint(
      Matrix4.inverted(transform),
      globalPos,
    );
  }

  /// 开始连接（从照片图钉精确位置触发）
  void startConnectingFromPhoto(
      int fromPhotoId, Offset globalPos, PhotoCard photo, Matrix4 transform) {
    _session = ConnectionSession(
      fromPhotoId: fromPhotoId,
      fromPos: photoPushpinPosition(photo),
    );
    connectingCurrentPos = MatrixUtils.transformPoint(
      Matrix4.inverted(transform),
      globalPos,
    );
  }

  /// 更新连接线终点位置（带吸附逻辑）
  ///
  /// 在用户拖拽过程中每帧调用，完成两个任务：
  /// 1. 将手指的全局坐标转换为画布坐标，更新连接线终点
  /// 2. 检测是否接近某个目标图钉（卡片或照片），如果是则吸附
  ///
  /// [inverseTransform] 为已缓存的逆矩阵，避免每帧重复计算。
  void updateConnecting(
    Offset globalPos,
    Matrix4 inverseTransform,
    List<ClueCard> cards,
    List<PhotoCard> photos,
    double canvasScale,
  ) {
    final session = _session;
    if (session == null) return;

    final canvasPos = MatrixUtils.transformPoint(
      inverseTransform,
      globalPos,
    );

    Offset snappedPos = canvasPos;
    double closestDist = WallConstants.connectionSnapRadius / canvasScale;

    // 吸附到卡片图钉
    for (final card in cards) {
      if (card.id == session.fromCardId) continue;
      final pinPos = pushpinPosition(card);
      final dist = (canvasPos - pinPos).distance;
      if (dist < closestDist) {
        closestDist = dist;
        snappedPos = pinPos;
      }
    }

    // 吸附到照片图钉
    for (final photo in photos) {
      if (photo.id == session.fromPhotoId) continue;
      final pinPos = photoPushpinPosition(photo);
      final dist = (canvasPos - pinPos).distance;
      if (dist < closestDist) {
        closestDist = dist;
        snappedPos = pinPos;
      }
    }

    connectingCurrentPos = snappedPos;
  }

  /// 完成连接
  ///
  /// 返回连接目标的信息：如果是卡片则返回 cardId，如果是照片则返回 photoId。
  /// 两者都为 null 表示未找到有效目标。
  ({int? cardId, int? photoId})? finishConnecting(
    List<ClueCard> cards,
    List<PhotoCard> photos,
    double canvasScale,
  ) {
    final session = _session;
    if (session == null) {
      endConnecting();
      return null;
    }

    // 检查卡片目标
    for (final card in cards) {
      if (card.id == session.fromCardId) continue;
      final pinPos = pushpinPosition(card);
      final distance = (connectingCurrentPos - pinPos).distance;
      if (distance < WallConstants.connectionFinishRadius / canvasScale) {
        return (cardId: card.id, photoId: null);
      }
    }

    // 检查照片目标
    for (final photo in photos) {
      if (photo.id == session.fromPhotoId) continue;
      final pinPos = photoPushpinPosition(photo);
      final distance = (connectingCurrentPos - pinPos).distance;
      if (distance < WallConstants.connectionFinishRadius / canvasScale) {
        return (cardId: null, photoId: photo.id);
      }
    }

    endConnecting();
    return null;
  }

  /// 结束连接状态
  void endConnecting() {
    _session = null;
  }
}
