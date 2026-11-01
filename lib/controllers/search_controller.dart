/// 搜索控制器 —— 管理搜索状态和匹配逻辑
///
/// 从 clue_wall_screen.dart 提取的搜索相关逻辑，包括：
/// - 搜索关键词管理
/// - 跨卡片/照片/连线的搜索匹配
/// - 搜索结果导航（自动定位到第一个匹配项）
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/connection_model.dart';
import '../models/photo_card_model.dart';
import '../models/rendered_connection.dart';
import '../providers/handlers/canvas_navigation_handler.dart';
import '../theme/wall_constants.dart';

/// 搜索结果
typedef SearchResult = ({
  Set<int> cardIds,
  Set<int> photoIds,
  Set<int> connectionIds,
});

/// 搜索控制器
///
/// 管理搜索 UI 状态和匹配逻辑，供 ClueWallScreen 使用。
class AppSearchController extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();

  static const _debounceDuration = Duration(milliseconds: 250);
  Timer? _debounceTimer;

  String _query = '';
  String get query => _query;

  bool _showSearch = false;
  bool get showSearch => _showSearch;

  SearchResult _results = (cardIds: <int>{}, photoIds: <int>{}, connectionIds: <int>{});
  SearchResult get results => _results;

  bool get isSearching => _query.isNotEmpty;
  int get resultCount =>
      _results.cardIds.length + _results.photoIds.length + _results.connectionIds.length;

  /// 更新搜索关键词，带 250ms 防抖
  ///
  /// [onSearched] 在防抖结束后、搜索完成时回调，用于触发导航和 setState。
  void updateQuery(String query, {
    required List<ClueCard> cards,
    required List<PhotoCard> photos,
    required List<Connection> connections,
    VoidCallback? onSearched,
  }) {
    _query = query;
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      _results = (cardIds: <int>{}, photoIds: <int>{}, connectionIds: <int>{});
      notifyListeners();
      onSearched?.call();
    } else {
      // 立即通知 UI 更新关键词（让搜索图标等状态同步）
      notifyListeners();
      _debounceTimer = Timer(_debounceDuration, () {
        _results = _searchAll(cards, photos, connections, query);
        notifyListeners();
        onSearched?.call();
      });
    }
  }

  /// 切换搜索栏显示状态
  void toggle() {
    _showSearch = !_showSearch;
    if (!_showSearch) {
      textController.clear();
      _query = '';
      _results = (cardIds: <int>{}, photoIds: <int>{}, connectionIds: <int>{});
    }
    notifyListeners();
  }

  /// 关闭搜索
  void close() {
    _showSearch = false;
    textController.clear();
    _query = '';
    _results = (cardIds: <int>{}, photoIds: <int>{}, connectionIds: <int>{});
    notifyListeners();
  }

  /// 根据搜索关键词过滤卡片、照片和连线
  static SearchResult _searchAll(
    List<ClueCard> cards,
    List<PhotoCard> photos,
    List<Connection> connections,
    String query,
  ) {
    final lowerQuery = query.toLowerCase();
    final cardIds = <int>{};
    final photoIds = <int>{};
    final connectionIds = <int>{};

    for (final card in cards) {
      if (card.id == null) continue;
      if (card.name.toLowerCase().contains(lowerQuery)) {
        cardIds.add(card.id!);
      } else if (card.description?.toLowerCase().contains(lowerQuery) ?? false) {
        cardIds.add(card.id!);
      } else if (card.tags.any((t) => t.toLowerCase().contains(lowerQuery))) {
        cardIds.add(card.id!);
      }
    }

    for (final photo in photos) {
      if (photo.id == null) continue;
      if (photo.caption?.toLowerCase().contains(lowerQuery) ?? false) {
        photoIds.add(photo.id!);
      }
    }

    for (final conn in connections) {
      if (conn.id == null) continue;
      if (conn.label?.toLowerCase().contains(lowerQuery) ?? false) {
        connectionIds.add(conn.id!);
      }
    }

    return (cardIds: cardIds, photoIds: photoIds, connectionIds: connectionIds);
  }

  /// 导航到第一个搜索结果
  void navigateToFirstResult({
    required List<ClueCard> cards,
    required List<PhotoCard> photos,
    required List<RenderedConnection> renderedConnections,
    required TransformationController transformController,
    required AnimationController zoomController,
    required CanvasNavigationHandler navigationHandler,
    required Size screenSize,
  }) {
    if (_query.isEmpty) return;

    // 优先定位到匹配的卡片
    if (_results.cardIds.isNotEmpty) {
      final card = cards.firstWhere((c) => c.id == _results.cardIds.first);
      navigationHandler.zoomToCard(
        transformController, zoomController,
        card.x, card.y, screenSize,
        cardWidth: card.width, cardHeight: card.height,
      );
      return;
    }

    // 其次定位到匹配的照片
    if (_results.photoIds.isNotEmpty) {
      final photo = photos.firstWhere((p) => p.id == _results.photoIds.first);
      navigationHandler.zoomToCard(
        transformController, zoomController,
        photo.x, photo.y, screenSize,
        cardWidth: photo.width, cardHeight: photo.height,
      );
      return;
    }

    // 匹配连线时，定位到连线中点
    if (_results.connectionIds.isNotEmpty) {
      final rc = renderedConnections.firstWhere(
        (r) => r.connectionId == _results.connectionIds.first,
        orElse: () => renderedConnections.first,
      );
      if (rc.points.length >= 4) {
        final mid = Offset(
          (rc.points[0].dx + rc.points[3].dx) / 2,
          (rc.points[0].dy + rc.points[3].dy) / 2,
        );
        navigationHandler.zoomToCard(
          transformController, zoomController,
          mid.dx - WallConstants.cardWidth / 2,
          mid.dy - WallConstants.cardHeight / 2,
          screenSize,
          cardWidth: WallConstants.cardWidth,
          cardHeight: WallConstants.cardHeight,
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    textController.dispose();
    super.dispose();
  }
}
