/// 线索墙主屏幕 —— Reticence 应用的核心视图
///
/// 本文件实现了侦探风格线索墙的完整交互界面。用户可以在软木板上
/// 钉线索卡片、照片卡片，并用红线将它们连接起来，模拟侦探推理时
/// 的线索墙效果。
///
/// 主要组件结构：
/// - [ClueWallScreen]：主屏幕入口，Riverpod 状态消费者
/// - [_ClueWallScreenState]：核心状态管理，包含画布变换、拖拽、
///   连线、导航、搜索、选择和照片操作等全部逻辑
/// - [ThreadLayer]：红线连接渲染层，使用 [RedThreadPainter] 绘制
/// - [TopBar]：顶部栏，含搜索功能
/// - [ConnectingHint]：连线模式下的操作提示
/// - [ToolButtons] / [ToolButton]：右下角工具按钮组
/// - [SearchResultBadge]：搜索结果计数徽章
/// - [CanvasGestureHandler]：自定义手势处理器，管理平移、缩放、
///   点击、长按和双击等画布交互
/// - [ConnectingLinePainter]：连线动画绘制器
/// - [EmptyStateHint]：空状态使用引导
///
/// 图层排列顺序（从下到上）：
/// 1. 普通卡片（normal cards）—— 被红线覆盖
/// 2. 独立照片卡片
/// 3. 红线层（IgnorePointer，触摸穿透）
/// 4. 正在连线的动态线（IgnorePointer）
/// 5. 浮动/选中卡片（floating cards）—— 在红线之上，可交互
/// 6. 正在拖拽的照片
/// 7. 搜索结果徽章 / 空状态提示
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/card_model.dart';
import '../models/connection_model.dart';
import '../models/photo_card_model.dart';
import '../models/rendered_connection.dart';
import '../models/thread_pluck_event.dart';
import '../providers/card_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/handlers/clue_wall_controller.dart';
import '../providers/connection_render_provider.dart';
import '../providers/relationship_filter_provider.dart';
import '../providers/undo_redo_provider.dart';
import '../providers/commands/card_commands.dart';
import '../providers/commands/connection_commands.dart';
import '../theme/app_colors.dart';
import '../theme/wall_constants.dart';
import '../utils/app_haptics.dart';
import '../utils/canvas_matrix.dart';
import '../widgets/add_photo_menu.dart';
import '../widgets/clue_card_widget.dart';
import '../widgets/dialogs/add_card_dialog.dart';
import '../widgets/dialogs/card_detail_dialog.dart';
import '../widgets/dialogs/connection_detail_dialog.dart';
import '../widgets/dialogs/photo_detail_dialog.dart';
import '../widgets/dialogs/photo_style_picker.dart';
import '../widgets/painters/app_state_widgets.dart';
import '../widgets/painters/paper_texture_background.dart';
import '../widgets/painters/red_thread_painter.dart';
import '../widgets/photo_card_widget.dart';
import 'canvas_gesture_handler.dart';
import 'connecting_hint.dart';
import 'connecting_line_painter.dart';
import 'empty_state_hint.dart';
import 'focus_mode_badge.dart';
import 'relationship_legend_bar.dart';
import 'search_result_badge.dart';
import 'thread_layer.dart';
import 'tool_buttons.dart';
import 'top_bar.dart';

/// 线索墙主屏幕
///
/// Reticence 应用的核心入口页面。使用 [ConsumerStatefulWidget] 以便
/// 订阅 Riverpod 状态。内部状态由 [_ClueWallScreenState] 管理，
/// 该 State 混入了 [TickerProviderStateMixin]（提供动画控制器 vsync）。
class ClueWallScreen extends ConsumerStatefulWidget {
  const ClueWallScreen({super.key});

  @override
  ConsumerState<ClueWallScreen> createState() => _ClueWallScreenState();
}

/// 线索墙核心状态管理器
///
/// 职责涵盖以下几大模块：
/// - **画布变换**：通过 [TransformationController] 管理平移/缩放矩阵，
///   支持双指缩放、双击自适应、边界约束等
/// - **交互编排**：委托给 [ClueWallController]，统一管理卡片、照片、
///   连线的交互流程
/// - **搜索与选择**：搜索过滤卡片、选中卡片高亮其关联卡片
///
/// 状态变量之间的关系：
/// - [_controller]：交互控制器，管理所有业务逻辑
/// - [_cardPointerDown] 与 [_canvasPinching]：这两个标志用于区分
///   手指是在卡片上操作还是在画布上操作，避免手势冲突
class _ClueWallScreenState extends ConsumerState<ClueWallScreen>
    with TickerProviderStateMixin {
  /// 画布变换控制器，管理平移和缩放的 4x4 矩阵
  final TransformationController _transformController =
      TransformationController();

  /// 缓存的逆矩阵，避免每帧重复计算昂贵的 Matrix4.inverted
  Matrix4 _cachedInverse = Matrix4.identity();

  /// 当前画布缩放比，通过 ValueNotifier 传递给 ThreadLayer，避免全屏 setState
  final ValueNotifier<double> _canvasScaleNotifier = ValueNotifier(1.0);
  final ValueNotifier<int> _canvasMotionNotifier = ValueNotifier(0);

  /// 长按红线时发出的拨动事件（连线 ID + 触点画布坐标）
  final ValueNotifier<ThreadPluckEvent?> _threadPluckNotifier =
      ValueNotifier(null);

  /// 缩放动画控制器（用于平滑缩放到目标位置）
  late AnimationController _zoomController;

  /// 连线动画控制器，控制连线出现时的淡入效果
  late AnimationController _connectingAnimController;

  /// 交互控制器，管理卡片/照片/连线的交互逻辑
  late final ClueWallController _controller;

  /// 共享浮动动画：所有卡片共用一个 Ticker 驱动浮动效果
  final ValueNotifier<double> _floatTimeNotifier = ValueNotifier(0);
  late final Ticker _floatTicker;

  bool _didCenterInitialCanvas = false;

  /// 工具按钮组的 GlobalKey，用于画布点击时收起展开菜单
  final _toolButtonsKey = GlobalKey<ToolButtonsState>();

  /// 画布截图用的 GlobalKey，用于导出功能
  final _canvasBoundaryKey = GlobalKey();

  /// 手指是否正在卡片上按下（用于区分手势是作用于卡片还是画布）
  final ValueNotifier<bool> _cardPointerDown = ValueNotifier(false);

  /// 画布是否正在进行双指缩放操作
  final ValueNotifier<bool> _canvasPinching = ValueNotifier(false);


  /// 初始化控制器和监听器
  ///
  /// - 创建动画控制器：缩放动画、连线淡入
  /// - 通过 addPostFrameCallback 在首帧渲染后设置 Riverpod 监听器
  @override
  void initState() {
    super.initState();
    _controller = ClueWallController(ref: ref);
    _transformController.addListener(_onTransformChanged);
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: WallConstants.animationDurationMs),
    );
    _connectingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: WallConstants.connectingAnimDurationMs),
    );
    _floatTicker = createTicker((elapsed) {
      _floatTimeNotifier.value = elapsed.inMicroseconds / 1000000.0;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCanvasOnInitialEntry();
      _setupListeners();
    });
  }

  /// 释放所有控制器
  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _canvasScaleNotifier.dispose();
    _canvasMotionNotifier.dispose();
    _threadPluckNotifier.dispose();
    _cardPointerDown.dispose();
    _canvasPinching.dispose();
    _transformController.dispose();
    _zoomController.dispose();
    _connectingAnimController.dispose();
    _floatTicker.dispose();
    _floatTimeNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// TransformationController 的监听器
  ///
  /// 当 _transformController.value 被直接修改时（如双指缩放、动画），
  /// 同步更新 canvasScale（通过 notifier 传递给 ThreadLayer）和缓存逆矩阵。
  /// 不调用 setState()，避免每帧重建整个屏幕。
  void _onTransformChanged() {
    _controller.navigationHandler.onTransformationUpdate(_transformController.value);
    _cachedInverse = Matrix4.inverted(_transformController.value);
    _canvasScaleNotifier.value = _controller.navigationHandler.canvasScale;
    _canvasMotionNotifier.value++;
  }

  void _centerCanvasOnInitialEntry() {
    if (_didCenterInitialCanvas || !mounted) return;
    final screenSize = MediaQuery.of(context).size;
    if (screenSize.isEmpty) return;

    const scale = 1.0;
    final tx = screenSize.width / 2 - WallConstants.canvasWidth * scale / 2;
    final ty = screenSize.height / 2 - WallConstants.canvasHeight * scale / 2;

    _transformController.value = canvasMatrixFromScaleAndTranslation(
      scale: scale,
      tx: tx,
      ty: ty,
    );
    _didCenterInitialCanvas = true;
  }

  Offset _viewportCenterInCanvas() {
    final screenSize = MediaQuery.of(context).size;
    final screenCenter = Offset(
      screenSize.width / 2,
      screenSize.height / 2,
    );
    return MatrixUtils.transformPoint(_cachedInverse, screenCenter);
  }

  /// 在当前视口范围内随机生成一个不与现有卡片重叠的位置
  Offset _randomPositionInViewport() {
    final screenSize = MediaQuery.of(context).size;
    final scale = _controller.navigationHandler.canvasScale;
    // 视口在画布坐标系中的范围
    final viewportLeft = -_transformController.value.getTranslation().x / scale;
    final viewportTop = -_transformController.value.getTranslation().y / scale;
    final viewportWidth = screenSize.width / scale;
    final viewportHeight = screenSize.height / scale;

    // 边距，避免卡片贴边
    const margin = WallConstants.placementMargin;
    const cardW = WallConstants.cardWidth;
    const cardH = WallConstants.cardHeight;

    final minX = viewportLeft + margin;
    final maxX = viewportLeft + viewportWidth - cardW - margin;
    final minY = viewportTop + margin;
    final maxY = viewportTop + viewportHeight - cardH - margin;

    if (maxX <= minX || maxY <= minY) {
      return _viewportCenterInCanvas();
    }

    // 获取现有卡片和照片位置
    final existingCards = ref.read(cardListProvider).value ?? [];
    final existingPhotos = ref.read(photoListProvider).value ?? [];
    final rng = Random();

    // 尝试找到不重叠的位置
    for (int attempt = 0; attempt < WallConstants.placementRetryLimit; attempt++) {
      final x = minX + rng.nextDouble() * (maxX - minX);
      final y = minY + rng.nextDouble() * (maxY - minY);

      bool overlaps = false;
      for (final card in existingCards) {
        final dx = (card.x - x).abs();
        final dy = (card.y - y).abs();
        if (dx < cardW * WallConstants.overlapFactor && dy < cardH * WallConstants.overlapFactor) {
          overlaps = true;
          break;
        }
      }
      if (!overlaps) {
        const photoW = WallConstants.photoCardWidth;
        const photoH = WallConstants.photoCardHeight;
        for (final photo in existingPhotos) {
          final dx = (photo.x - x).abs();
          final dy = (photo.y - y).abs();
          if (dx < photoW * WallConstants.overlapFactor && dy < photoH * WallConstants.overlapFactor) {
            overlaps = true;
            break;
          }
        }
      }
      if (!overlaps) return Offset(x, y);
    }

    // 兜底：视口内随机位置
    return Offset(
      minX + rng.nextDouble() * (maxX - minX),
      minY + rng.nextDouble() * (maxY - minY),
    );
  }

  /// 约束画布边界，防止用户将画布拖出可视范围
  void _clampCanvasBounds() {
    _controller.navigationHandler.clampCanvasBounds(
      _transformController,
      _zoomController,
      MediaQuery.of(context).size,
    );
  }

  /// 缩放画布以适应所有卡片和独立照片
  ///
  /// 计算所有元素的边界矩形，然后调用导航处理器的
  /// zoomToFit 方法将画布缩放到恰好包含所有内容。
  void _zoomToFit(List<ClueCard> cards) {
    final bounds = <({double x, double y, double w, double h})>[];

    for (final c in cards) {
      bounds.add((x: c.x, y: c.y, w: c.width, h: c.height));
    }

    final photosAsync = ref.read(photoListProvider);
    photosAsync.whenData((photos) {
      for (final p in photos) {
        bounds.add((x: p.x, y: p.y, w: p.width, h: p.height));
      }
    });

    if (bounds.isEmpty) return;
    _controller.navigationHandler.zoomToFit(
      _transformController,
      _zoomController,
      bounds,
      MediaQuery.of(context).size,
    );
  }

  /// 缩放画布以聚焦到指定卡片
  void _zoomToCard(ClueCard card) {
    _controller.navigationHandler.zoomToCard(
      _transformController,
      _zoomController,
      card.x,
      card.y,
      MediaQuery.of(context).size,
      cardWidth: card.width,
      cardHeight: card.height,
    );
  }

  /// 卡片拖拽开始回调
  ///
  /// 如果正在连线模式则忽略拖拽。否则：
  /// 1. 触发触觉反馈
  /// 2. 委托给 [DragHandler] 记录起始状态
  void _onCardDragStart(int cardId, Offset globalPosition) {
    if (_controller.connectionHandler.isConnecting) return;
    final card = _controller.findCard(cardId);
    if (card == null) return;
    AppHaptics.selection();
    setState(() {
      _controller.dragHandler.onDragStart(cardId, globalPosition, card);
    });
  }

  /// 卡片拖拽更新回调
  ///
  /// 将全局坐标增量转换为画布坐标（除以当前缩放比例），
  /// 更新内存中的卡片位置（不持久化）。
  void _onCardDragUpdate(Offset globalPosition) {
    if (_canvasPinching.value) return;
    if (!_controller.dragHandler.isDragging) return;
    // 通知红线层：卡片拖拽也触发绳子摆动
    _canvasMotionNotifier.value++;
    final pos = _controller.dragHandler.onDragUpdate(
        globalPosition, _controller.navigationHandler.canvasScale);
    if (pos == null) return;
    ref.read(cardListProvider.notifier).updateCardPositionInMemory(
          _controller.dragHandler.draggingCardId!,
          pos.dx,
          pos.dy,
        );
  }

  /// 卡片拖拽结束回调
  ///
  /// 拖拽结束后有两种情况：
  /// - **越界回弹**：卡片被拖出画布边界，需要弹回到安全位置，
  ///   此时更新位置到回弹目标并持久化
  /// - **正常结束**：卡片在画布内，直接持久化当前位置
  void _onCardDragEnd() {
    // 在结束拖拽前记录旧位置（onDragEnd 会清除会话）
    final oldPos = _controller.dragHandler.cardStartPos;
    final cardId = _controller.dragHandler.onDragEnd();
    if (cardId != null) {
      AppHaptics.light();

      if (_controller.dragHandler.isBeyondBoundary) {
        final springBackTarget = _controller.dragHandler.getSpringBackTarget();
        ref.read(cardListProvider.notifier).updateCardPosition(
              cardId,
              springBackTarget.dx,
              springBackTarget.dy,
            );
        // 注册撤销命令
        ref.read(undoRedoProvider.notifier).executeCommand(
              MoveCardsCommand(
                ref.read(cardListProvider.notifier),
                {cardId: (oldPos.dx, oldPos.dy)},
                {cardId: (springBackTarget.dx, springBackTarget.dy)},
              ),
            );
      } else {
        // 获取当前位置
        final card = ref.read(cardListProvider).value?.firstWhereOrNull(
              (c) => c.id == cardId,
            );
        if (card != null) {
          final newPos = (card.x, card.y);
          if (oldPos.dx != newPos.$1 || oldPos.dy != newPos.$2) {
            // 注册撤销命令
            ref.read(undoRedoProvider.notifier).executeCommand(
                  MoveCardsCommand(
                    ref.read(cardListProvider.notifier),
                    {cardId: (oldPos.dx, oldPos.dy)},
                    {cardId: newPos},
                  ),
                );
          }
        }
        ref.read(cardListProvider.notifier).persistCardPosition(cardId);
      }
    }
  }

  void _handleCanvasPinchStatusChanged(bool pinching) {
    if (pinching) {
      _cancelActiveDragsForCanvasGesture();
    }
    if (mounted) {
      _canvasPinching.value = pinching;
    }
  }

  void _cancelActiveDragsForCanvasGesture() {
    final draggingCardId = _controller.dragHandler.draggingCardId;
    final draggingPhotoId = _controller.photoDragHandler.draggingPhotoId;

    if (draggingCardId != null) {
      unawaited(ref
          .read(cardListProvider.notifier)
          .persistCardPosition(draggingCardId));
      _controller.dragHandler.reset();
    }

    if (draggingPhotoId != null) {
      unawaited(ref
          .read(photoListProvider.notifier)
          .persistPhotoPosition(draggingPhotoId));
      _controller.photoDragHandler.reset();
    }

    if (_cardPointerDown.value || _controller.photoDragHandler.isDragging) {
      setState(() {
        _cardPointerDown.value = false;
      });
    }
  }

  /// 从卡片详情对话框发起连线
  ///
  /// 用户在卡片详情中点击"连线"按钮时触发，
  /// 进入连线模式等待用户点击目标卡片。
  void _startConnecting(int fromCardId) {
    final card = _controller.findCard(fromCardId);
    if (card == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _controller.connectionHandler.startConnecting(fromCardId, card);
    });
  }

  /// 从卡片图钉长按发起连线
  void _startConnectingFromPin(int fromCardId, Offset globalPos) {
    final card = _controller.findCard(fromCardId);
    if (card == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _controller.connectionHandler.startConnectingFromPin(
          fromCardId, globalPos, card, _transformController.value);
    });
    _connectingAnimController.forward(from: 0);
  }

  /// 从照片图钉长按发起连线
  void _startConnectingFromPhotoPin(int fromPhotoId, Offset globalPos) {
    final photo = _controller.findPhoto(fromPhotoId);
    if (photo == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _controller.connectionHandler.startConnectingFromPhoto(
          fromPhotoId, globalPos, photo, _transformController.value);
    });
    _connectingAnimController.forward(from: 0);
  }

  /// 完成连线操作
  ///
  /// 连线完成时的核心流程：
  /// 1. 检查是否处于连线模式，否则直接结束
  /// 2. 调用 [ConnectionHandler.finishConnecting] 检测手指下方是否有目标
  /// 3. 如果检测到目标卡片/照片，调用 [_tryConnect] 尝试建立连接
  /// 5. 如果没有检测到目标，直接取消连线
  Future<void> _finishConnecting() async {
    if (!_controller.connectionHandler.isConnecting ||
        (_controller.connectionHandler.connectingFromCardId == null &&
            _controller.connectionHandler.connectingFromPhotoId == null)) {
      _endConnecting();
      return;
    }

    final cards = ref.read(cardListProvider).value ?? [];
    final photos = ref.read(photoListProvider).value ?? [];
    final result = _controller.connectionHandler.finishConnecting(
        cards, photos, _controller.navigationHandler.canvasScale);

    if (result != null) {
      if (result.cardId != null) {
        await _tryConnect(toCardId: result.cardId!);
      } else if (result.photoId != null) {
        await _tryConnect(toPhotoId: result.photoId!);
      }
    } else {
      _endConnecting();
    }
  }

  /// 更新连线跟踪位置（拖拽过程中持续调用）
  void _updateConnecting(Offset globalPos) {
    if (!_controller.connectionHandler.isConnecting) return;
    final cards = ref.read(cardListProvider).value ?? [];
    final photos = ref.read(photoListProvider).value ?? [];
    setState(() {
      _controller.connectionHandler.updateConnecting(globalPos, _cachedInverse,
          cards, photos, _controller.navigationHandler.canvasScale);
    });
  }

  /// 结束连线模式，重置连线和动画状态
  void _endConnecting() {
    if (!_controller.connectionHandler.isConnecting) return;
    _connectingAnimController.reset();
    setState(() {
      _controller.connectionHandler.endConnecting();
    });
  }

  /// 尝试与目标卡片建立连线
  ///
  /// 连线创建的完整逻辑：
  /// 1. 验证是否处于连线模式且有源卡片
  /// 2. 不允许自连接（源卡片 == 目标卡片时取消）
  /// 3. 检查是否已存在相同连线（双向去重）
  /// 4. 通过 Riverpod provider 持久化新连线
  /// 5. 创建成功后触发中等强度触觉反馈，并自动打开关系详情面板
  ///    让用户立即选择关系类型、填写关系描述
  Future<void> _tryConnect({int? toCardId, int? toPhotoId}) async {
    if (!_controller.connectionHandler.isConnecting) return;
    final fromCardId = _controller.connectionHandler.connectingFromCardId;
    final fromPhotoId = _controller.connectionHandler.connectingFromPhotoId;

    // 不允许自连接
    if (fromCardId != null && fromCardId == toCardId) {
      _endConnecting();
      return;
    }
    if (fromPhotoId != null && fromPhotoId == toPhotoId) {
      _endConnecting();
      return;
    }

    final existing = ref.read(connectionListProvider).value ?? [];
    final alreadyConnected = existing.any((c) => c.connectsEndpoints(
          fromCardId: fromCardId,
          fromPhotoId: fromPhotoId,
          toCardId: toCardId,
          toPhotoId: toPhotoId,
        ));

    if (alreadyConnected) {
      AppHaptics.selection();
      _endConnecting();
      return;
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
      final created = command.createdConnection!;
      // 新建后清除筛选，确保新线立即可见
      ref.read(relationshipFilterProvider.notifier).state =
          const <ConnectionType>{};
      _endConnecting();
      // 等当前指针事件处理完毕再弹面板，避免与手势收尾竞争
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showConnectionDetail(created);
      });
      return;
    }
    _endConnecting();
  }

  /// 当前筛选/聚焦下可被点击/拨动的连线
  ///
  /// 被筛选或聚焦淡化的连线不可命中；搜索命中的连线即使被筛选也保持可交互，
  /// 避免用户搜到却点不到。
  List<RenderedConnection> _hittableRenderedConnections() {
    final rendered = ref.read(renderedConnectionsProvider);
    final filter = ref.read(relationshipFilterProvider);
    final searchIds = _controller.searchCtrl.results.connectionIds;
    final focusActive = _isFocusActive;
    final focusIds = _controller.selection.highlightedConnectionIds;

    if (filter.isEmpty && !focusActive) return rendered;

    return rendered.where((conn) {
      final typeVisible = filter.isEmpty ||
          filter.contains(conn.connectionType) ||
          searchIds.contains(conn.connectionId);
      final focusVisible = !focusActive ||
          focusIds.contains(conn.connectionId) ||
          searchIds.contains(conn.connectionId);
      return typeVisible && focusVisible;
    }).toList();
  }

  /// 画布点击处理
  ///
  /// 点击画布空白区域时的逻辑：
  /// 1. 取消焦点（收起键盘）
  /// 2. 如果正在连线模式，取消连线
  /// 3. 按当前聚焦/筛选状态检测是否点击了红线
  /// 4. 命中红线时打开详情并保留聚焦；未命中时清除选中/聚焦
  void _handleCanvasTap(TapUpDetails details) {
    FocusManager.instance.primaryFocus?.unfocus();
    _toolButtonsKey.currentState?.collapse();

    if (_controller.connectionHandler.isConnecting) {
      _endConnecting();
      return;
    }

    // 先按点击前的聚焦状态确定可命中连线，避免点击淡化线时
    // 先清除选中导致它重新变成可命中。
    final renderedConnections = _hittableRenderedConnections();

    // 将屏幕坐标转换为画布坐标，用于检测是否点击了红线
    final canvasPos = MatrixUtils.transformPoint(
      _cachedInverse,
      details.globalPosition,
    );

    // 使用 RedThreadPainter 的命中测试检测是否点击了红线
    // 命中阈值根据当前缩放比例调整，缩放越小阈值越大
    final hitId = RedThreadPainter.hitTestConnection(
      canvasPos,
      renderedConnections,
      WallConstants.connectionHitThreshold / _controller.navigationHandler.canvasScale,
    );

    if (hitId != null) {
      final connections = ref.read(connectionListProvider).value ?? [];
      final conn = connections.where((c) => c.id == hitId).firstOrNull;
      if (conn != null) _showConnectionDetail(conn);
      return;
    }

    _clearSelection();
  }

  /// 画布长按处理 —— 拨动红线
  ///
  /// 长按画布空白区域时，检测是否按在红线上。
  /// 如果命中红线，触发触觉反馈，并在触点注入局部波动；
  /// 波动会沿绳子传播，并通过共享卡片传导到相邻连线。
  void _handleCanvasLongPress(Offset globalPosition) {
    if (_controller.connectionHandler.isConnecting) return;

    final canvasPos = MatrixUtils.transformPoint(
      _cachedInverse,
      globalPosition,
    );

    final renderedConnections = _hittableRenderedConnections();
    final hitId = RedThreadPainter.hitTestConnection(
      canvasPos,
      renderedConnections,
      WallConstants.connectionHitThreshold / _controller.navigationHandler.canvasScale,
    );

    if (hitId != null) {
      HapticFeedback.mediumImpact();
      _canvasMotionNotifier.value++;
      _threadPluckNotifier.value = ThreadPluckEvent(
        connectionId: hitId,
        position: canvasPos,
      );
    }
  }

  // ---- 照片操作方法 ----

  /// 显示添加照片的底部菜单
  void _showAddPhotoMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddPhotoMenu(
        onCancel: () => Navigator.pop(ctx),
        onPhotoSelected: (image) async {
          Navigator.pop(ctx);
          showPhotoStylePicker(context, onStyleSelected: (style) {
            _createIndependentPhoto(image, style);
          });
        },
      ),
    );
  }

  /// 创建独立照片卡片
  ///
  /// 将照片放置在当前画布视口中心位置，
  /// 并赋予随机旋转角度以增加真实感。
  Future<void> _createIndependentPhoto(XFile image, PhotoStyle style) async {
    final canvasPos = _randomPositionInViewport();

    final random = Random();
    final rotationDegrees = (random.nextDouble() * WallConstants.maxPhotoRotationDegrees * 2 - WallConstants.maxPhotoRotationDegrees).toDouble();
    final rotation = rotationDegrees * pi / 180; // 转换为弧度，与 ClueCard 保持一致

    final photo = PhotoCard(
      imagePath: image.path,
      photoStyle: style,
      x: canvasPos.dx - WallConstants.photoCardWidth / 2,
      y: canvasPos.dy - WallConstants.photoCardHeight / 2,
      rotation: rotation,
    );

    await ref.read(undoRedoProvider.notifier).executeCommand(
          AddPhotoCommand(ref.read(photoListProvider.notifier), photo),
        );
  }

  /// 照片拖拽开始回调
  void _onPhotoDragStart(int photoId, Offset globalPos) {
    AppHaptics.selection();
    final photo = _controller.findPhoto(photoId);
    if (photo == null) return;

    setState(() {
      _controller.photoDragHandler.onDragStart(photoId, globalPos, photo);
    });
  }

  /// 照片拖拽更新回调
  void _onPhotoDragUpdate(Offset globalPos) {
    if (_canvasPinching.value) return;
    if (!_controller.photoDragHandler.isDragging) return;
    _canvasMotionNotifier.value++;

    final pos = _controller.photoDragHandler.onDragUpdate(
        globalPos, _controller.navigationHandler.canvasScale);
    if (pos == null) return;

    ref
        .read(photoListProvider.notifier)
        .updatePhotoPositionInMemory(
            _controller.photoDragHandler.draggingPhotoId!, pos.dx, pos.dy);
  }

  /// 照片拖拽结束回调
  ///
  /// 拖拽结束后有两种情况：
  /// - **越界回弹**：照片被拖出画布边界，需要弹回到安全位置，
  ///   此时更新位置到回弹目标并持久化
  /// - **正常结束**：照片在画布内，直接持久化当前位置
  Future<void> _onPhotoDragEnd() async {
    // 在结束拖拽前记录旧位置（onDragEnd 会清除会话）
    final oldPos = _controller.photoDragHandler.photoStartPos;
    final photoId = _controller.photoDragHandler.onDragEnd();

    if (photoId != null) {
      AppHaptics.light();

      if (_controller.photoDragHandler.isBeyondBoundary) {
        final springBackTarget = _controller.photoDragHandler.getSpringBackTarget();
        ref.read(photoListProvider.notifier).updatePhotoPosition(
              photoId,
              springBackTarget.dx,
              springBackTarget.dy,
            );
        // 注册撤销命令
        ref.read(undoRedoProvider.notifier).executeCommand(
              MovePhotosCommand(
                ref.read(photoListProvider.notifier),
                {photoId: (oldPos.dx, oldPos.dy)},
                {photoId: (springBackTarget.dx, springBackTarget.dy)},
              ),
            );
      } else {
        // 获取当前位置
        final photo = ref.read(photoListProvider).value?.firstWhereOrNull(
              (p) => p.id == photoId,
            );
        if (photo != null) {
          final newPos = (photo.x, photo.y);
          if (oldPos.dx != newPos.$1 || oldPos.dy != newPos.$2) {
            // 注册撤销命令
            ref.read(undoRedoProvider.notifier).executeCommand(
                  MovePhotosCommand(
                    ref.read(photoListProvider.notifier),
                    {photoId: (oldPos.dx, oldPos.dy)},
                    {photoId: newPos},
                  ),
                );
          }
        }
        ref.read(photoListProvider.notifier).persistPhotoPosition(photoId);
      }
    }
  }

  /// 设置 Riverpod 状态监听器
  ///
  /// 监听卡片/连线/照片错误，数据操作失败时显示错误信息和重试按钮
  void _setupListeners() {
    _listenToError(cardErrorProvider, cardListProvider);
    _listenToError(connectionErrorProvider, connectionListProvider);
    _listenToError(photoErrorProvider, photoListProvider);

    // 连线增删后刷新聚焦网络，避免新增关系仍被淡化、已删关系残留
    ref.listenManual(connectionListProvider, (previous, next) {
      final connections = next.value;
      if (connections == null || !_controller.selection.hasSelection) return;

      final selectedCardId = _controller.selection.selectedCardId;
      final selectedPhotoId = _controller.selection.selectedPhotoId;
      if (selectedCardId != null) {
        _controller.selection.selectCard(selectedCardId, connections);
      } else if (selectedPhotoId != null) {
        _controller.selection.selectPhoto(selectedPhotoId, connections);
      }
      if (mounted) setState(() {});
    });
  }

  /// 监听单个错误 Provider，失败时显示 SnackBar + 重试
  void _listenToError(
    StateProvider<String?> errorProvider,
    ProviderBase<Object?> listProvider,
  ) {
    ref.listenManual(errorProvider, (prev, next) {
      _showErrorSnackBar(next, () => ref.invalidate(listProvider));
      if (next != null) ref.read(errorProvider.notifier).state = null;
    });
  }

  /// 显示错误 SnackBar
  void _showErrorSnackBar(String? message, VoidCallback onRetry) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.sepia.withValues(alpha: 0.9),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '重试',
          textColor: AppColors.redThread,
          onPressed: onRetry,
        ),
      ),
    );
  }

  /// 显示添加卡片对话框
  ///
  /// [canvasPosition] 为卡片在画布上的放置位置。
  /// 卡片添加成功后延迟一小段时间自动缩放定位到新卡片。
  void _showAddCardDialog(Offset canvasPosition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddCardDialog(
        canvasPosition: canvasPosition,
        onCardAdded: (card) {
          Future.delayed(
              const Duration(milliseconds: WallConstants.zoomDelayMs), () {
            if (mounted) {
              _zoomToCard(card);
            }
          });
        },
      ),
    );
  }

  /// 显示卡片详情对话框
  ///
  /// 双击卡片时触发，提供编辑和发起连线等操作。
  void _showCardDetail(ClueCard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CardDetailDialog(
        card: card,
        onStartConnecting: () => _startConnecting(card.id!),
      ),
    );
  }

  /// 显示连线详情对话框
  ///
  /// 点击红线时触发，可查看和编辑连线标签。
  void _showConnectionDetail(Connection connection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConnectionDetailDialog(connection: connection),
    );
  }

  /// 是否处于关系网络聚焦模式
  ///
  /// 搜索时让位给搜索结果高亮；连线时暂停淡化，方便看清可连接目标。
  bool get _isFocusActive =>
      _controller.selection.hasSelection &&
      !_controller.searchCtrl.isSearching &&
      !_controller.connectionHandler.isConnecting;

  /// 聚焦徽章上显示的线索名称
  String? _focusLabel(List<ClueCard> cards, List<PhotoCard> photos) {
    if (!_isFocusActive) return null;

    final cardId = _controller.selection.selectedCardId;
    if (cardId != null) {
      return cards.firstWhereOrNull((card) => card.id == cardId)?.name ?? '线索';
    }

    final photoId = _controller.selection.selectedPhotoId;
    if (photoId != null) {
      final caption =
          photos.firstWhereOrNull((photo) => photo.id == photoId)?.caption?.trim();
      return caption == null || caption.isEmpty ? '照片' : caption;
    }
    return '线索';
  }

  /// 选中一张卡片
  ///
  /// 将该卡片及其所有直接关联卡片加入高亮集合，
  /// 实现"选中即高亮关联网络"的视觉效果。
  void _selectCard(int cardId) {
    _controller.selectCard(cardId);
    setState(() {});
  }

  /// 清除卡片/照片选中状态和高亮集合
  /// 删除当前选中的卡片或照片
  void _deleteSelected() {
    _controller.deleteSelected();
    setState(() {});
  }

  void _clearSelection() {
    if (!_controller.selection.hasSelection) return;
    _controller.clearSelection();
    setState(() {});
  }

  /// 更新浮动动画 Ticker 状态
  ///
  /// 当有卡片或照片处于选中/高亮状态时启动 Ticker，否则停止。
  /// 避免在没有浮动卡片时持续运行 Ticker 浪费资源。
  void _updateFloatTicker(List<ClueCard> cards, List<PhotoCard> photos) {
    final shouldRun = _controller.hasFloatingCards(cards, photos);

    if (shouldRun && !_floatTicker.isActive) {
      _floatTicker.start();
    } else if (!shouldRun && _floatTicker.isActive) {
      _floatTicker.stop();
    }
  }

  /// 搜索输入变化处理
  void _onSearchChanged(
    String query,
    List<ClueCard> cards,
    List<PhotoCard> photos,
    List<Connection> connections,
  ) {
    _controller.searchCtrl.updateQuery(query,
        cards: cards,
        photos: photos,
        connections: connections,
        onSearched: () {
      _controller.searchCtrl.navigateToFirstResult(
        cards: cards,
        photos: photos,
        renderedConnections: ref.read(renderedConnectionsProvider),
        transformController: _transformController,
        zoomController: _zoomController,
        navigationHandler: _controller.navigationHandler,
        screenSize: MediaQuery.of(context).size,
      );
      setState(() {});
    });
    setState(() {});
  }

  /// 构建线索墙主界面
  ///
  /// 整体结构为全屏 Stack，从下到上依次为：
  /// 1. 软木板纹理背景 + 画布手势处理器（含画布内容）
  /// 2. 顶部栏（标题 + 搜索）
  /// 3. 连线提示（连线模式下显示）
  /// 4. 工具按钮组（右下角）
  ///
  /// 画布内部的图层排列（从下到上）：
  /// - 普通卡片（被红线覆盖，营造红线"穿过"卡片的视觉效果）
  /// - 独立照片卡片
  /// - 红线层（IgnorePointer，触摸穿透到下层卡片）
  /// - 正在连线的动态线（IgnorePointer）
  /// - 浮动/选中卡片（在红线之上，确保可交互且视觉突出）
  /// - 正在拖拽的照片
  /// - 搜索结果徽章 / 空状态提示
  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardListProvider);
    final connectionsAsync = ref.watch(connectionListProvider);
    final photosAsync = ref.watch(photoListProvider);

    // 数据加载中也先显示画布，避免欢迎页之后再出现整屏加载层。
    if (cardsAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.corkBoard,
        body: AppErrorWidget(message: '加载失败：${cardsAsync.error}'),
      );
    }
    if (connectionsAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.corkBoard,
        body: AppErrorWidget(message: '加载失败：${connectionsAsync.error}'),
      );
    }
    if (photosAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.corkBoard,
        body: AppErrorWidget(message: '加载失败：${photosAsync.error}'),
      );
    }

    final cards = cardsAsync.value ?? const <ClueCard>[];
    final connections = connectionsAsync.value ?? const <Connection>[];
    final photos = photosAsync.value ?? const <PhotoCard>[];
    final focusLabel = _focusLabel(cards, photos);

    // 根据是否有浮动卡片启停 Ticker
    _updateFloatTicker(cards, photos);

    return _ClueWallShortcuts(
      showSearch: _controller.searchCtrl.showSearch,
      hasSelection: _controller.selection.hasSelection,
      onCloseSearch: () {
        _controller.searchCtrl.close();
        setState(() {});
      },
      onClearSelection: _clearSelection,
      onUndo: () => ref.read(undoRedoProvider.notifier).undo(),
      onRedo: () => ref.read(undoRedoProvider.notifier).redo(),
      onDelete: _deleteSelected,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: WallConstants.systemUiOverlayStyle,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          body: Builder(
            builder: (context) {
              // 构建连线标签映射表：连线 ID → 标签文本
              final connectionLabels = <int, String?>{};
              for (final conn in connections) {
                if (conn.id != null) {
                  connectionLabels[conn.id!] = conn.label;
                }
              }

              // 搜索匹配结果：卡片、照片、连线
              // 搜索状态由 AppSearchController 管理
              final isSearching = _controller.searchCtrl.isSearching;
              final focusActive = _isFocusActive;
              final searchMatches = _controller.searchCtrl.results;
              final cardWidgets = _buildCardWidgets(
                  cards, isSearching ? searchMatches.cardIds : null);
              final photoWidgets = _buildPhotoWidgets(
                  photos, isSearching ? searchMatches.photoIds : null);

              return RepaintBoundary(
                key: _canvasBoundaryKey,
                child: Stack(
                children: [
                  PaperTextureBackground(
                    baseColor: AppColors.corkBoard,
                    showAging: false,
                    showCoffeeStain: false,
                    showFoldLine: false,
                    mode: TextureMode.cork,
                    frameStyle: FrameStyle.none,
                    child: CanvasGestureHandler(
                        transformController: _transformController,
                        zoomController: _zoomController,
                        onInteractionEnd: () => _clampCanvasBounds(),
                        connectionHandler: _controller.connectionHandler,
                        updateConnecting: (pos) => _updateConnecting(pos),
                        isCardInteracting: () =>
                            _cardPointerDown.value || _controller.dragHandler.isDragging,
                        onPinchStatusChanged: _handleCanvasPinchStatusChanged,
                        onTap: (details) => _handleCanvasTap(details),
                        onDoubleTap: () => _zoomToFit(cards),
                        onLongPress: (globalPos) =>
                            _handleCanvasLongPress(globalPos),
                        child: SizedBox(
                        width: WallConstants.canvasWidth,
                        height: WallConstants.canvasHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // === 第 1 层：普通卡片 ===
                            // 非选中/非高亮的卡片放在红线之下，
                            // 营造红线"穿过"卡片的视觉效果
                            ...cardWidgets.normal,
                            // === 第 2 层：独立照片卡片 ===
                            // 独立照片也在红线之下
                            ...photoWidgets.photos,
                            // === 第 3 层：红线连接层 ===
                            // 使用 IgnorePointer 使触摸事件穿透到下层卡片
                            ThreadLayer(
                              canvasScaleNotifier: _canvasScaleNotifier,
                              canvasMotionNotifier: _canvasMotionNotifier,
                              connectionLabels: connectionLabels,
                              pluckNotifier: _threadPluckNotifier,
                              focusActive: focusActive,
                              focusConnectionIds:
                                  _controller.selection.highlightedConnectionIds,
                              highlightedConnectionIds: isSearching
                                  ? searchMatches.connectionIds
                                  : const {},
                            ),
                            // === 第 4 层：正在连线的动态线 ===
                            // 连线模式下从源卡片到手指位置的动态红线，
                            // IgnorePointer 避免阻挡下层交互
                            if (_controller.connectionHandler.isConnecting)
                              IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _connectingAnimController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: const Size(
                                          WallConstants.canvasWidth,
                                          WallConstants.canvasHeight),
                                      painter: ConnectingLinePainter(
                                        from: _controller.connectionHandler
                                            .connectingFromPos,
                                        to: _controller.connectionHandler
                                            .connectingCurrentPos,
                                        opacity:
                                            _connectingAnimController.value,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            // === 第 5 层：浮动/选中卡片 ===
                            // 选中或高亮的卡片放在红线之上，确保：
                            // 1. 视觉上突出显示（不被红线遮挡）
                            // 2. 交互上可正常响应触摸事件
                            ...cardWidgets.floating,
                            // === 第 6 层：正在拖拽的照片 ===
                            // 拖拽中的照片放在最上层
                            ...photoWidgets.floating,
                            // === 第 7 层：搜索结果徽章 / 空状态提示 ===
                            if (isSearching)
                              SearchResultBadge(count: _controller.searchCtrl.resultCount),
                            if (cards.isEmpty && photos.isEmpty)
                              const Positioned.fill(
                                child: Center(child: EmptyStateHint()),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TopBar(
                    showSearch: _controller.searchCtrl.showSearch,
                    searchController: _controller.searchCtrl.textController,
                    cardCount: cards.length,
                    legend: const RelationshipLegendBar(),
                    onSearchChanged: (query) =>
                        _onSearchChanged(query, cards, photos, connections),
                    onSearchToggle: () {
                      _controller.searchCtrl.toggle();
                      setState(() {});
                    },
                  ),
                  if (focusLabel != null)
                    FocusModeBadge(
                      label: focusLabel,
                      onClear: _clearSelection,
                    ),
                  if (_controller.connectionHandler.isConnecting) const ConnectingHint(),
                  ToolButtons(
                    key: _toolButtonsKey,
                    onAddPhoto: _showAddPhotoMenu,
                    onAddCard: () {
                      _showAddCardDialog(_randomPositionInViewport());
                    },
                  ),
                ],
              ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 构建卡片 Widget 列表，分为普通层和浮动层
  ///
  /// 卡片分层的核心原因：
  /// - **普通层（normal）**：放在红线之下，红线"穿过"这些卡片，
  ///   模拟真实线索墙上红线钉在卡片上方的效果
  /// - **浮动层（floating）**：选中或高亮的卡片放在红线之上，
  ///   确保这些卡片视觉突出且可正常交互
  ///
  /// 每张卡片的交互回调说明：
  /// - onTap：连线模式下尝试连接目标卡片，否则切换选中状态
  /// - onDoubleTap：打开卡片详情对话框
  /// - onDragStart/Update/End：卡片拖拽生命周期
  /// - onPinLongPressStart/Move/End：从图钉发起的连线拖拽
  ({List<Widget> normal, List<Widget> floating}) _buildCardWidgets(
    List<ClueCard> cards,
    Set<int>? matchIds,
  ) {
    final normal = <Widget>[];
    final floating = <Widget>[];

    final focusActive = _isFocusActive;
    final focusCardIds = _controller.selection.highlightedCardIds;

    for (final card in cards) {
      final isMatch =
          matchIds != null && matchIds.contains(card.id); // 是否匹配搜索结果
      final isFloating = card.id != null &&
          _controller.selection.highlightedCardIds.contains(card.id!); // 是否需要浮动（选中/高亮）
      final isPrimary = card.id == _controller.selection.selectedCardId; // 是否为当前选中的主卡片
      final isFocusDimmed = focusActive &&
          (card.id == null || !focusCardIds.contains(card.id)); // 是否不属于聚焦网络

      final widget = Positioned(
        left: card.x,
        top: card.y,
        child: RepaintBoundary(
          child: ClueCardWidget(
            key: ValueKey(card.id),
            card: card,
            scale: _controller.navigationHandler.canvasScale,
            isConnectingTarget: _controller.connectionHandler.isConnecting &&
                card.id !=
                    _controller.connectionHandler
                        .connectingFromCardId, // 连线模式下非源卡片显示为可连接目标
            isHighlighted: isMatch,
            isFloating: isFloating,
            isPrimary: isPrimary,
            isDimmed: isFocusDimmed,
            isCanvasPinching: _canvasPinching.value,
            onPointerDown: () => _cardPointerDown.value = true,
            onPointerUp: () => _cardPointerDown.value = false,
            onTap: () async {
              if (_controller.connectionHandler.isConnecting && card.id != null) {
                await _tryConnect(toCardId: card.id!);
              } else if (card.id != null) {
                if (_controller.selection.selectedCardId == card.id) {
                  _clearSelection();
                } else {
                  _selectCard(card.id!);
                }
              }
            },
            onDoubleTap: () {
              _showCardDetail(card);
            },
            onDragStart: (globalPos) {
              if (!_controller.connectionHandler.isConnecting && !_canvasPinching.value) {
                _onCardDragStart(card.id!, globalPos);
              }
            },
            onDragUpdate: _onCardDragUpdate,
            onDragEnd: _onCardDragEnd,
            onPinLongPressStart: (globalPos) {
              if (!_controller.connectionHandler.isConnecting && card.id != null) {
                _startConnectingFromPin(card.id!, globalPos);
              }
            },
            onPinLongPressMove: (globalPos) {
              _updateConnecting(globalPos);
            },
            onPinLongPressEnd: () async {
              await _finishConnecting();
            },
            floatTimeNotifier: _floatTimeNotifier,
          ),
        ),
      );

      // 根据是否浮动决定放入哪一层
      if (isFloating) {
        floating.add(widget);
      } else {
        normal.add(widget);
      }
    }

    return (normal: normal, floating: floating);
  }

  /// 构建照片 Widget 列表，分为普通层和浮动层
  ///
  /// 分层逻辑与卡片相同：选中的照片浮动到红线之上。
  ({List<Widget> photos, List<Widget> floating}) _buildPhotoWidgets(
    List<PhotoCard> photos,
    Set<int>? matchIds,
  ) {
    final photoWidgets = <Widget>[];
    final floatingWidgets = <Widget>[];

    final focusActive = _isFocusActive;
    final focusPhotoIds = _controller.selection.highlightedPhotoIds;

    for (final photo in photos) {
      final isMatch = matchIds != null && matchIds.contains(photo.id);
      final isPrimary = photo.id == _controller.selection.selectedPhotoId;
      final isFloating = photo.id != null &&
          (_controller.selection.selectedPhotoId == photo.id ||
              _controller.selection.highlightedPhotoIds.contains(photo.id));
      final isFocusDimmed = focusActive &&
          (photo.id == null || !focusPhotoIds.contains(photo.id));

      final widget = Positioned(
        left: photo.x,
        top: photo.y,
        child: RepaintBoundary(
          child: PhotoCardWidget(
            key: ValueKey(photo.id),
            photo: photo,
            isPrimary: isPrimary,
            isHighlighted: isMatch || isFloating,
            isDimmed: isFocusDimmed,
            isConnectingTarget: _controller.connectionHandler.isConnecting &&
                photo.id != _controller.connectionHandler.connectingFromPhotoId,
            onPointerDown: () => _cardPointerDown.value = true,
            onPointerUp: () => _cardPointerDown.value = false,
            onDragStart: (globalPos) {
              if (photo.id != null && !_canvasPinching.value) {
                _onPhotoDragStart(photo.id!, globalPos);
              }
            },
            onDragUpdate: _onPhotoDragUpdate,
            onDragEnd: _onPhotoDragEnd,
            onTap: () async {
              if (_controller.connectionHandler.isConnecting && photo.id != null) {
                await _tryConnect(toPhotoId: photo.id!);
              } else {
                if (_controller.selection.selectedPhotoId == photo.id) {
                  _clearSelection();
                } else {
                  setState(() {
                    _controller.selectPhoto(photo.id!);
                  });
                }
              }
            },
            onDoubleTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => PhotoDetailDialog(photo: photo),
              );
            },
            onPinLongPressStart: (globalPos) {
              if (!_controller.connectionHandler.isConnecting && photo.id != null) {
                _startConnectingFromPhotoPin(photo.id!, globalPos);
              }
            },
            onPinLongPressMove: (globalPos) {
              _updateConnecting(globalPos);
            },
            onPinLongPressEnd: () async {
              await _finishConnecting();
            },
          ),
        ),
      );

      if (isFloating) {
        floatingWidgets.add(widget);
      } else {
        photoWidgets.add(widget);
      }
    }

    return (photos: photoWidgets, floating: floatingWidgets);
  }
}

/// 键盘快捷键 + 返回键处理的包装层
///
/// 将 PopScope、Shortcuts、Actions 从主 build 方法中提取出来，
/// 降低嵌套深度，使主 build 方法专注于画布内容的组装。
class _ClueWallShortcuts extends StatelessWidget {
  const _ClueWallShortcuts({
    required this.showSearch,
    required this.hasSelection,
    required this.onCloseSearch,
    required this.onClearSelection,
    required this.onUndo,
    required this.onRedo,
    required this.onDelete,
    required this.child,
  });

  final bool showSearch;
  final bool hasSelection;
  final VoidCallback onCloseSearch;
  final VoidCallback onClearSelection;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !showSearch && !hasSelection,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (showSearch) {
          onCloseSearch();
        } else if (hasSelection) {
          onClearSelection();
        }
      },
      child: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
              const _UndoIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
              const _RedoIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
              LogicalKeyboardKey.keyZ): const _RedoIntent(),
          LogicalKeySet(LogicalKeyboardKey.delete): const _DeleteIntent(),
          LogicalKeySet(LogicalKeyboardKey.escape): const _EscapeIntent(),
        },
        child: Actions(
          actions: {
            _UndoIntent: CallbackAction<_UndoIntent>(
              onInvoke: (_) { onUndo(); return null; },
            ),
            _RedoIntent: CallbackAction<_RedoIntent>(
              onInvoke: (_) { onRedo(); return null; },
            ),
            _DeleteIntent: CallbackAction<_DeleteIntent>(
              onInvoke: (_) { onDelete(); return null; },
            ),
            _EscapeIntent: CallbackAction<_EscapeIntent>(
              onInvoke: (_) { onClearSelection(); return null; },
            ),
          },
          child: child,
        ),
      ),
    );
  }
}

/// 撤销意图
class _UndoIntent extends Intent {
  const _UndoIntent();
}

/// 重做意图
class _RedoIntent extends Intent {
  const _RedoIntent();
}

/// 删除意图
class _DeleteIntent extends Intent {
  const _DeleteIntent();
}

/// 退出意图
class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

// 以下 Widget 类已提取到独立文件，参见 lib/screens/ 目录
// 已提取的类：ThreadLayer, TopBar, ConnectingHint, ToolButtons, ToolButton,
// SearchResultBadge, CanvasGestureHandler, ConnectingLinePainter,
// EmptyStateHint, StyleOption
