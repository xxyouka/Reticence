import 'package:flutter/material.dart';

import '../../models/photo_card_model.dart';

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
/// 拖拽过程中仅更新内存位置（通过调用方调用 provider 的
/// updatePhotoPositionInMemory），松手后由调用方负责持久化和撤销注册。
class PhotoDragHandler {
  PhotoDragSession? _session;

  /// 当前是否正在拖拽照片
  bool get isDragging => _session != null;

  /// 当前正在拖拽的照片 ID
  int? get draggingPhotoId => _session?.photoId;

  /// 拖拽起始时照片的左上角位置（画布坐标系）
  Offset get photoStartPos => _session?.photoStartPos ?? Offset.zero;

  /// 开始拖拽
  void onDragStart(int photoId, Offset globalPosition, PhotoCard photo) {
    _session = PhotoDragSession(
      photoId: photoId,
      dragStart: globalPosition,
      photoStartPos: Offset(photo.x, photo.y),
    );
  }

  /// 拖拽更新
  ///
  /// 返回照片在画布坐标系中的新位置，由调用方写入 provider。
  Offset? onDragUpdate(Offset globalPosition, double canvasScale) {
    final session = _session;
    if (session == null) return null;

    final delta = (globalPosition - session.dragStart) / canvasScale;
    return session.photoStartPos + delta;
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
  }
}
