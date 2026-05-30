/// 线索墙交互控制器
///
/// 从 [ClueWallScreen] 中提取的交互编排逻辑，负责协调卡片、照片、连线
/// 的操作流程。本类为纯逻辑控制器，不持有 Flutter Widget 状态，
/// 通过回调与 UI 层通信。
///
/// 职责：
/// - 卡片拖拽流程编排（开始→更新→结束→持久化→撤销注册）
/// - 照片拖拽流程编排
/// - 连线操作流程编排（开始→跟踪→完成/取消）
/// - 选中状态管理
/// - 搜索逻辑协调
library;

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/card_model.dart';
import '../../models/connection_model.dart';
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
import '../../providers/commands/connection_commands.dart';
import '../../controllers/search_controller.dart' as sc;
import '../../theme/wall_constants.dart';
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

  // ========== 卡片拖拽 ==========

  /// 卡片拖拽开始
  void onCardDragStart(int cardId, Offset globalPosition) {
    if (connectionHandler.isConnecting) return;
    final card = findCard(cardId);
    if (card == null) return;
    AppHaptics.selection();
    dragHandler.onDragStart(cardId, globalPosition, card);
  }

  /// 卡片拖拽更新
  Offset? onCardDragUpdate(Offset globalPosition, double canvasScale) {
    if (!dragHandler.isDragging) return null;
    return dragHandler.onDragUpdate(globalPosition, canvasScale);
  }

  /// 卡片拖拽结束
  ///
  /// 处理越界回弹和位置持久化，返回撤销命令所需的信息。
  ({int cardId, Offset oldPos, Offset newPos})? onCardDragEnd() {
    final oldPos = dragHandler.cardStartPos;
    final cardId = dragHandler.onDragEnd();
    if (cardId == null) return null;

    AppHaptics.light();

    if (dragHandler.isBeyondBoundary) {
      final springBackTarget = dragHandler.getSpringBackTarget();
      ref.read(cardListProvider.notifier).updateCardPosition(
            cardId,
            springBackTarget.dx,
            springBackTarget.dy,
          );
      return (cardId: cardId, oldPos: oldPos, newPos: springBackTarget);
    } else {
      final card = findCard(cardId);
      if (card != null) {
        final newPos = Offset(card.x, card.y);
        if (oldPos.dx != newPos.dx || oldPos.dy != newPos.dy) {
          ref.read(cardListProvider.notifier).persistCardPosition(cardId);
          return (cardId: cardId, oldPos: oldPos, newPos: newPos);
        }
      }
      ref.read(cardListProvider.notifier).persistCardPosition(cardId);
      return null;
    }
  }

  // ========== 照片拖拽 ==========

  /// 照片拖拽开始
  void onPhotoDragStart(int photoId, Offset globalPosition) {
    AppHaptics.selection();
    final photo = findPhoto(photoId);
    if (photo == null) return;
    photoDragHandler.onDragStart(photoId, globalPosition, photo);
  }

  /// 照片拖拽更新
  Offset? onPhotoDragUpdate(Offset globalPosition, double canvasScale) {
    if (!photoDragHandler.isDragging) return null;
    return photoDragHandler.onDragUpdate(globalPosition, canvasScale);
  }

  /// 照片拖拽结束
  ///
  /// 处理越界回弹和位置持久化，返回撤销命令所需的信息。
  ({int photoId, Offset oldPos, Offset newPos})? onPhotoDragEnd() {
    final oldPos = photoDragHandler.photoStartPos;
    final photoId = photoDragHandler.onDragEnd();
    if (photoId == null) return null;

    AppHaptics.light();

    if (photoDragHandler.isBeyondBoundary) {
      final springBackTarget = photoDragHandler.getSpringBackTarget();
      ref.read(photoListProvider.notifier).updatePhotoPosition(
            photoId,
            springBackTarget.dx,
            springBackTarget.dy,
          );
      return (photoId: photoId, oldPos: oldPos, newPos: springBackTarget);
    } else {
      final photo = findPhoto(photoId);
      if (photo != null) {
        final newPos = Offset(photo.x, photo.y);
        if (oldPos.dx != newPos.dx || oldPos.dy != newPos.dy) {
          ref.read(photoListProvider.notifier).persistPhotoPosition(photoId);
          return (photoId: photoId, oldPos: oldPos, newPos: newPos);
        }
      }
      ref.read(photoListProvider.notifier).persistPhotoPosition(photoId);
      return null;
    }
  }

  // ========== 连线操作 ==========

  /// 从卡片图钉发起连线
  void startConnectingFromPin(int fromCardId, Offset globalPos, Matrix4 transformMatrix) {
    final card = findCard(fromCardId);
    if (card == null) return;
    HapticFeedback.mediumImpact();
    connectionHandler.startConnectingFromPin(
        fromCardId, globalPos, card, transformMatrix);
  }

  /// 从照片图钉发起连线
  void startConnectingFromPhotoPin(int fromPhotoId, Offset globalPos, Matrix4 transformMatrix) {
    final photo = findPhoto(fromPhotoId);
    if (photo == null) return;
    HapticFeedback.mediumImpact();
    connectionHandler.startConnectingFromPhoto(
        fromPhotoId, globalPos, photo, transformMatrix);
  }

  /// 更新连线跟踪位置
  void updateConnecting(Offset globalPos, Matrix4 inverseMatrix, double canvasScale) {
    if (!connectionHandler.isConnecting) return;
    final cards = ref.read(cardListProvider).value ?? [];
    final photos = ref.read(photoListProvider).value ?? [];
    connectionHandler.updateConnecting(
        globalPos, inverseMatrix, cards, photos, canvasScale);
  }

  /// 完成连线操作
  ///
  /// 返回连线目标信息，如果没有目标则返回 null。
  ({int? cardId, int? photoId})? finishConnecting(double canvasScale) {
    if (!connectionHandler.isConnecting) return null;

    final cards = ref.read(cardListProvider).value ?? [];
    final photos = ref.read(photoListProvider).value ?? [];
    return connectionHandler.finishConnecting(cards, photos, canvasScale);
  }

  /// 尝试与目标建立连接
  Future<bool> tryConnect({int? toCardId, int? toPhotoId}) async {
    if (!connectionHandler.isConnecting) return false;

    final fromCardId = connectionHandler.connectingFromCardId;
    final fromPhotoId = connectionHandler.connectingFromPhotoId;

    // 不允许自连接
    if (fromCardId != null && fromCardId == toCardId) return false;
    if (fromPhotoId != null && fromPhotoId == toPhotoId) return false;

    // 检查是否已存在相同连线
    final existing = ref.read(connectionListProvider).value ?? [];
    final alreadyConnected = existing.any((c) => c.connectsEndpoints(
          fromCardId: fromCardId,
          fromPhotoId: fromPhotoId,
          toCardId: toCardId,
          toPhotoId: toPhotoId,
        ));

    if (alreadyConnected) {
      AppHaptics.selection();
      return false;
    }

    AppHaptics.light();
    final command = AddConnectionCommand(
      ref.read(connectionListProvider.notifier),
      Connection(
        fromCardId: fromCardId,
        toCardId: toCardId,
        fromPhotoId: fromPhotoId,
        toPhotoId: toPhotoId,
      ),
    );
    await ref.read(undoRedoProvider.notifier).executeCommand(command);
    if (command.createdConnection != null) {
      AppHaptics.connect();
      return true;
    }
    return false;
  }

  /// 取消连线
  void cancelConnecting() {
    connectionHandler.endConnecting();
  }

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

  // ========== 搜索 ==========

  /// 搜索输入变化
  void onSearchChanged(
    String query,
    List<ClueCard> cards,
    List<PhotoCard> photos,
    List<Connection> connections,
    VoidCallback onSearched,
  ) {
    searchCtrl.updateQuery(
      query,
      cards: cards,
      photos: photos,
      connections: connections,
      onSearched: onSearched,
    );
  }

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
