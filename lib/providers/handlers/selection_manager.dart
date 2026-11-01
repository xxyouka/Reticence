import '../../models/connection_model.dart';

/// 选中状态管理器
///
/// 管理线索墙上卡片和照片的选中/高亮状态。
/// 选中一张卡片时，其直接关联的卡片和照片也会被高亮，
/// 实现"选中即高亮关联网络"的视觉效果。
///
/// 本类为纯逻辑类，不依赖 Riverpod 或 Flutter 框架。
/// connections 列表作为参数传入，由调用方负责从 provider 读取。
class SelectionManager {
  /// 当前选中的卡片 ID
  int? selectedCardId;

  /// 当前选中的照片 ID
  int? selectedPhotoId;

  /// 高亮卡片 ID 集合（选中卡片的直接关联卡片）
  final Set<int> highlightedCardIds = {};

  /// 高亮照片 ID 集合（选中卡片的直接关联照片）
  final Set<int> highlightedPhotoIds = {};

  /// 聚焦网络内的连线 ID 集合（与选中卡片/照片直接相连的连线）
  ///
  /// 用于聚焦模式下保持这些连线完整显示，其余连线淡化。
  /// 每次选择都替换为新集合，确保渲染层能通过引用变化感知网络切换。
  Set<int> highlightedConnectionIds = {};

  /// 是否有任何选中项
  bool get hasSelection => selectedCardId != null || selectedPhotoId != null;

  /// 选中一张卡片
  ///
  /// 将该卡片及其所有直接关联卡片/照片加入高亮集合。
  void selectCard(int cardId, List<Connection> connections) {
    final connectedCardIds = <int>{};
    final connectedPhotoIds = <int>{};
    final connectedConnectionIds = <int>{};

    for (final conn in connections) {
      if (conn.id != null &&
          (conn.fromCardId == cardId || conn.toCardId == cardId)) {
        connectedConnectionIds.add(conn.id!);
      }
      if (conn.fromCardId == cardId && conn.toCardId != null) {
        connectedCardIds.add(conn.toCardId!);
      }
      if (conn.toCardId == cardId && conn.fromCardId != null) {
        connectedCardIds.add(conn.fromCardId!);
      }
      if (conn.fromCardId == cardId && conn.toPhotoId != null) {
        connectedPhotoIds.add(conn.toPhotoId!);
      }
      if (conn.toCardId == cardId && conn.fromPhotoId != null) {
        connectedPhotoIds.add(conn.fromPhotoId!);
      }
    }

    selectedCardId = cardId;
    highlightedCardIds
      ..clear()
      ..add(cardId)
      ..addAll(connectedCardIds);
    highlightedPhotoIds
      ..clear()
      ..addAll(connectedPhotoIds);
    highlightedConnectionIds = connectedConnectionIds;
  }

  /// 选中一张照片
  ///
  /// 将该照片及其所有直接关联卡片/照片加入高亮集合。
  /// 与 [selectCard] 逻辑对称，确保选中照片时也能看到关联网络。
  void selectPhoto(int photoId, List<Connection> connections) {
    final connectedCardIds = <int>{};
    final connectedPhotoIds = <int>{};
    final connectedConnectionIds = <int>{};

    for (final conn in connections) {
      if (conn.id != null &&
          (conn.fromPhotoId == photoId || conn.toPhotoId == photoId)) {
        connectedConnectionIds.add(conn.id!);
      }
      if (conn.fromPhotoId == photoId && conn.toCardId != null) {
        connectedCardIds.add(conn.toCardId!);
      }
      if (conn.toPhotoId == photoId && conn.fromCardId != null) {
        connectedCardIds.add(conn.fromCardId!);
      }
      if (conn.fromPhotoId == photoId && conn.toPhotoId != null) {
        connectedPhotoIds.add(conn.toPhotoId!);
      }
      if (conn.toPhotoId == photoId && conn.fromPhotoId != null) {
        connectedPhotoIds.add(conn.fromPhotoId!);
      }
    }

    selectedPhotoId = photoId;
    highlightedCardIds
      ..clear()
      ..addAll(connectedCardIds);
    highlightedPhotoIds
      ..clear()
      ..add(photoId)
      ..addAll(connectedPhotoIds);
    highlightedConnectionIds = connectedConnectionIds;
  }

  /// 清除所有选中状态
  void clearSelection() {
    selectedCardId = null;
    selectedPhotoId = null;
    highlightedCardIds.clear();
    highlightedPhotoIds.clear();
    highlightedConnectionIds = {};
  }
}
