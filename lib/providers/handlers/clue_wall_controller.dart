/// 线索墙交互控制器
///
/// 从 [ClueWallScreen] 中提取的交互编排逻辑，负责协调卡片、照片、连线
/// 的操作流程。本类为纯逻辑控制器，不持有 Flutter Widget 状态，
/// 通过回调与 UI 层通信。
///
/// 职责：
/// - 管理各处理器（拖拽、连线、导航、选中）的生命周期
/// - 提供统一的查找和状态查询接口
/// - 封装删除选中项的业务逻辑
library;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/card_model.dart';
import '../../models/photo_card_model.dart';
import '../../providers/card_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/photo_provider.dart';
import '../../providers/handlers/canvas_navigation_handler.dart';
import '../../providers/handlers/connection_handler.dart';
import '../../providers/handlers/drag_handler.dart';
import '../../providers/handlers/photo_drag_handler.dart';
import '../../providers/handlers/selection_manager.dart';
import '../../providers/undo_redo_provider.dart';
import '../../providers/commands/card_commands.dart';
import '../../controllers/search_controller.dart' as sc;
import '../../utils/app_haptics.dart';

/// 线索墙交互控制器
///
/// 管理线索墙的所有交互逻辑，与 UI 层通过回调通信。
/// 使用 [WidgetRef] 读取 Riverpod 状态，但不持有 Widget 状态。
class ClueWallController {
  final WidgetRef ref;

  /// 卡片拖拽处理器
  final DragHandler dragHandler = DragHandler();

  /// 照片拖拽处理器
  final PhotoDragHandler photoDragHandler = PhotoDragHandler();

  /// 连线操作处理器
  final ConnectionHandler connectionHandler = ConnectionHandler();

  /// 画布导航处理器
  final CanvasNavigationHandler navigationHandler = CanvasNavigationHandler();

  /// 选中状态管理器
  final SelectionManager selection = SelectionManager();

  /// 搜索控制器
  final sc.AppSearchController searchCtrl = sc.AppSearchController();

  ClueWallController({required this.ref});

  /// 按 ID 查找卡片
  ClueCard? findCard(int id) =>
      ref.read(cardListProvider).value?.firstWhereOrNull((c) => c.id == id);

  /// 按 ID 查找照片
  PhotoCard? findPhoto(int id) =>
      ref.read(photoListProvider).value?.firstWhereOrNull((p) => p.id == id);

  // ========== 选中操作 ==========

  /// 选中卡片
  void selectCard(int cardId) {
    AppHaptics.light();
    final connections = ref.read(connectionListProvider).value ?? [];
    selection.selectCard(cardId, connections);
  }

  /// 选中照片
  void selectPhoto(int photoId) {
    final connections = ref.read(connectionListProvider).value ?? [];
    selection.selectPhoto(photoId, connections);
  }

  /// 清除选中
  void clearSelection() {
    selection.clearSelection();
  }

  /// 删除选中项
  void deleteSelected() {
    if (selection.selectedCardId != null) {
      final cardId = selection.selectedCardId!;
      final card = findCard(cardId);
      if (card != null) {
        final connections = ref.read(connectionListProvider).value ?? [];
        final relatedConnections = connections
            .where((c) => c.fromCardId == cardId || c.toCardId == cardId)
            .toList();
        ref.read(undoRedoProvider.notifier).executeCommand(
              DeleteCardCommand(
                ref.read(cardListProvider.notifier),
                ref.read(connectionListProvider.notifier),
                card,
                relatedConnections,
              ),
            );
      }
      clearSelection();
    } else if (selection.selectedPhotoId != null) {
      final photoId = selection.selectedPhotoId!;
      final photo = findPhoto(photoId);
      if (photo != null) {
        final connections = ref.read(connectionListProvider).value ?? [];
        final relatedConnections = connections
            .where((c) => c.fromPhotoId == photoId || c.toPhotoId == photoId)
            .toList();
        ref.read(undoRedoProvider.notifier).executeCommand(
              DeletePhotoCommand(
                ref.read(photoListProvider.notifier),
                ref.read(connectionListProvider.notifier),
                photo,
                relatedConnections,
              ),
            );
      }
      clearSelection();
    }
  }

  // ========== 查询 ==========

  /// 检查是否有浮动卡片
  bool hasFloatingCards(List<ClueCard> cards, List<PhotoCard> photos) {
    final hasFloatingCards = cards.any((c) =>
        c.id != null && selection.highlightedCardIds.contains(c.id!));
    final hasFloatingPhotos = photos.any((p) =>
        p.id != null &&
        (selection.selectedPhotoId == p.id ||
            selection.highlightedPhotoIds.contains(p.id!)));
    return hasFloatingCards || hasFloatingPhotos;
  }

  /// 释放资源
  void dispose() {
    searchCtrl.dispose();
  }
}
