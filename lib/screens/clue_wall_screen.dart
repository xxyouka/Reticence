/// 线索墙主屏幕 —— Reticence 应用的核心视图
///
/// 本文件实现了侦探风格线索墙的完整交互界面。用户可以在软木板上
/// 钉人物卡片、照片卡片，并用红线将它们连接起来，模拟侦探推理时
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
import '../providers/card_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/handlers/canvas_navigation_handler.dart';
import '../providers/handlers/connection_handler.dart';
import '../providers/handlers/drag_handler.dart';
import '../providers/handlers/photo_drag_handler.dart';
import '../providers/handlers/selection_manager.dart';
import '../providers/connection_render_provider.dart';
import '../providers/undo_redo_provider.dart';
import '../providers/commands/card_commands.dart';
import '../providers/commands/connection_commands.dart';
import '../controllers/search_controller.dart' as sc;
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
/// - **卡片拖拽**：委托给 [DragHandler]，处理拖拽开始/更新/结束，
///   越界回弹、位置持久化等
/// - **连线操作**：委托给 [ConnectionHandler]，管理从图钉发起的
///   拖拽连线流程（开始→跟踪→完成/取消）
/// - **画布导航**：委托给 [CanvasNavigationHandler]，处理缩放动画、
///   适应屏幕、定位到指定卡片等
/// - **搜索与选择**：搜索过滤卡片、选中卡片高亮其关联卡片
/// - **照片操作**：独立照片的创建、拖拽
///
/// 状态变量之间的关系：
/// - [_selection]：选中状态管理器，管理卡片/照片的选中和高亮状态
/// - [_cardPointerDown] 与 [_canvasPinching]：这两个标志用于区分
///   手指是在卡片上操作还是在画布上操作，避免手势冲突
/// - [_photoDragHandler]：照片拖拽处理器，封装拖拽状态和位置计算逻辑
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

  /// 缩放动画控制器（用于平滑缩放到目标位置）
  late AnimationController _zoomController;

  /// 连线动画控制器，控制连线出现时的淡入效果
  late AnimationController _connectingAnimController;

  /// 卡片拖拽处理器，封装拖拽状态和位置计算逻辑
  final _dragHandler = DragHandler();

  /// 连线操作处理器，封装连线状态和目标检测逻辑
  final _connectionHandler = ConnectionHandler();

  /// 画布导航处理器，封装缩放动画和边界约束逻辑
  final _navigationHandler = CanvasNavigationHandler();

  /// 照片拖拽处理器，封装照片拖拽状态和位置计算逻辑
  final _photoDragHandler = PhotoDragHandler();

  /// 共享浮动动画：所有卡片共用一个 Ticker 驱动浮动效果
  final ValueNotifier<double> _floatTimeNotifier = ValueNotifier(0);
  late final Ticker _floatTicker;

  bool _didCenterInitialCanvas = false;

  /// 搜索控制器，封装搜索状态和匹配逻辑
  final _searchCtrl = sc.AppSearchController();

  /// 工具按钮组的 GlobalKey，用于画布点击时收起展开菜单
  final _toolButtonsKey = GlobalKey<ToolButtonsState>();

  /// 画布截图用的 GlobalKey，用于导出功能
  final _canvasBoundaryKey = GlobalKey();

  /// 选中状态管理器，管理卡片/照片的选中和高亮状态
  final _selection = SelectionManager();

  /// 按 ID 查找卡片（从 provider 缓存中读取）
  ClueCard? _findCard(int id) =>
      ref.read(cardListProvider).value?.firstWhereOrNull((c) => c.id == id);

  /// 按 ID 查找照片（从 provider 缓存中读取）
  PhotoCard? _findPhoto(int id) =>
      ref.read(photoListProvider).value?.firstWhereOrNull((p) => p.id == id);

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
    })..start();

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
    _cardPointerDown.dispose();
    _canvasPinching.dispose();
    _transformController.dispose();
    _zoomController.dispose();
    _connectingAnimController.dispose();
    _floatTicker.dispose();
    _floatTimeNotifier.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// TransformationController 的监听器
  ///
  /// 当 _transformController.value 被直接修改时（如双指缩放、动画），
  /// 同步更新 canvasScale（通过 notifier 传递给 ThreadLayer）和缓存逆矩阵。
  /// 不调用 setState()，避免每帧重建整个屏幕。
  void _onTransformChanged() {
    _navigationHandler.onTransformationUpdate(_transformController.value);
    _cachedInverse = Matrix4.inverted(_transformController.value);
    _canvasScaleNotifier.value = _navigationHandler.canvasScale;
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
    final scale = _navigationHandler.canvasScale;
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
        if (dx < cardW * 0.7 && dy < cardH * 0.7) {
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
          if (dx < photoW * 0.7 && dy < photoH * 0.7) {
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
    _navigationHandler.clampCanvasBounds(
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
    _navigationHandler.zoomToFit(
      _transformController,
      _zoomController,
      bounds,
      MediaQuery.of(context).size,
    );
  }

  /// 缩放画布以聚焦到指定卡片
  void _zoomToCard(ClueCard card) {
    _navigationHandler.zoomToCard(
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
    if (_connectionHandler.isConnecting) return;
    final card = _findCard(cardId);
    if (card == null) return;
    AppHaptics.selection();
    setState(() {
      _dragHandler.onDragStart(cardId, globalPosition, card);
    });
  }

  /// 卡片拖拽更新回调
  ///
  /// 将全局坐标增量转换为画布坐标（除以当前缩放比例），
  /// 更新内存中的卡片位置（不持久化）。
  void _onCardDragUpdate(Offset globalPosition) {
    if (_canvasPinching.value) return;
    if (!_dragHandler.isDragging) return;
    // 通知红线层：卡片拖拽也触发绳子摆动
    _canvasMotionNotifier.value++;
    final pos = _dragHandler.onDragUpdate(
        globalPosition, _navigationHandler.canvasScale);
    if (pos == null) return;
    ref.read(cardListProvider.notifier).updateCardPositionInMemory(
          _dragHandler.draggingCardId!,
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
    final oldPos = _dragHandler.cardStartPos;
    final cardId = _dragHandler.onDragEnd();
    if (cardId != null) {
      AppHaptics.light();

      if (_dragHandler.isBeyondBoundary) {
        final springBackTarget = _dragHandler.getSpringBackTarget();
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
    final draggingCardId = _dragHandler.draggingCardId;
    final draggingPhotoId = _photoDragHandler.draggingPhotoId;

    if (draggingCardId != null) {
      unawaited(ref
          .read(cardListProvider.notifier)
          .persistCardPosition(draggingCardId));
      _dragHandler.reset();
    }

    if (draggingPhotoId != null) {
      unawaited(ref
          .read(photoListProvider.notifier)
          .persistPhotoPosition(draggingPhotoId));
      _photoDragHandler.reset();
    }

    if (_cardPointerDown.value || _photoDragHandler.isDragging) {
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
    final card = _findCard(fromCardId);
    if (card == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _connectionHandler.startConnecting(fromCardId, card);
    });
  }

  /// 从卡片图钉长按发起连线
  void _startConnectingFromPin(int fromCardId, Offset globalPos) {
    final card = _findCard(fromCardId);
    if (card == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _connectionHandler.startConnectingFromPin(
          fromCardId, globalPos, card, _transformController.value);
    });
    _connectingAnimController.forward(from: 0);
  }

  /// 从照片图钉长按发起连线
  void _startConnectingFromPhotoPin(int fromPhotoId, Offset globalPos) {
    final photo = _findPhoto(fromPhotoId);
    if (photo == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _connectionHandler.startConnectingFromPhoto(
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
    if (!_connectionHandler.isConnecting ||
        (_connectionHandler.connectingFromCardId == null &&
            _connectionHandler.connectingFromPhotoId == null)) {
      _endConnecting();
      return;
    }

    final cards = ref.read(cardListProvider).value ?? [];
    final photos = ref.read(photoListProvider).value ?? [];
    final result = _connectionHandler.finishConnecting(
        cards, photos, _navigationHandler.canvasScale);

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
    if (!_connectionHandler.isConnecting) return;
    final cards = ref.read(cardListProvider).value ?? [];
    final photos = ref.read(photoListProvider).value ?? [];
    setState(() {
      _connectionHandler.updateConnecting(globalPos, _cachedInverse,
          cards, photos, _navigationHandler.canvasScale);
    });
  }

  /// 结束连线模式，重置连线和动画状态
  void _endConnecting() {
    if (!_connectionHandler.isConnecting) return;
    _connectingAnimController.reset();
    setState(() {
      _connectionHandler.endConnecting();
    });
  }

  /// 尝试与目标卡片建立连线
  ///
  /// 连线创建的完整逻辑：
  /// 1. 验证是否处于连线模式且有源卡片
  /// 2. 不允许自连接（源卡片 == 目标卡片时取消）
  /// 3. 检查是否已存在相同连线（双向去重）
  /// 4. 通过 Riverpod provider 持久化新连线
  /// 5. 创建成功后触发中等强度触觉反馈
  Future<void> _tryConnect({int? toCardId, int? toPhotoId}) async {
    if (!_connectionHandler.isConnecting) return;
    final fromCardId = _connectionHandler.connectingFromCardId;
    final fromPhotoId = _connectionHandler.connectingFromPhotoId;

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
    }
    _endConnecting();
  }

  /// 画布点击处理
  ///
  /// 点击画布空白区域时的逻辑：
  /// 1. 取消焦点（收起键盘）
  /// 2. 如果正在连线模式，取消连线
  /// 3. 清除卡片选中状态
  /// 4. 将屏幕坐标转换为画布坐标，检测是否点击了红线
  /// 5. 如果命中红线，显示连线详情对话框
  void _handleCanvasTap(TapUpDetails details) {
    FocusManager.instance.primaryFocus?.unfocus();
    _toolButtonsKey.currentState?.collapse();

    if (_connectionHandler.isConnecting) {
      _endConnecting();
      return;
    }

    _clearSelection();

    // 将屏幕坐标转换为画布坐标，用于检测是否点击了红线
    final canvasPos = MatrixUtils.transformPoint(
      _cachedInverse,
      details.globalPosition,
    );

    // 使用 RedThreadPainter 的命中测试检测是否点击了红线
    // 命中阈值根据当前缩放比例调整，缩放越小阈值越大
    final renderedConnections = ref.read(renderedConnectionsProvider);
    final hitId = RedThreadPainter.hitTestConnection(
      canvasPos,
      renderedConnections,
      WallConstants.connectionHitThreshold / _navigationHandler.canvasScale,
    );

    if (hitId != null) {
      final connections = ref.read(connectionListProvider).value ?? [];
      final conn = connections.where((c) => c.id == hitId).firstOrNull;
      if (conn != null) _showConnectionDetail(conn);
    }
  }

  /// 画布长按处理 —— 拨动红线
  ///
  /// 长按画布空白区域时，检测是否按在红线上。
  /// 如果命中红线，触发触觉反馈和绳子摆动动画。
  void _handleCanvasLongPress(Offset globalPosition) {
    if (_connectionHandler.isConnecting) return;

    final canvasPos = MatrixUtils.transformPoint(
      _cachedInverse,
      globalPosition,
    );

    final renderedConnections = ref.read(renderedConnectionsProvider);
    final hitId = RedThreadPainter.hitTestConnection(
      canvasPos,
      renderedConnections,
      WallConstants.connectionHitThreshold / _navigationHandler.canvasScale,
    );

    if (hitId != null) {
      HapticFeedback.mediumImpact();
      _canvasMotionNotifier.value++;
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
    final rotation = (random.nextDouble() * 10 - 5).toDouble();

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
    final photos = ref.read(photoListProvider).value ?? [];
    final photo = photos.firstWhereOrNull((p) => p.id == photoId);
    if (photo == null) return;

    setState(() {
      _photoDragHandler.onDragStart(photoId, globalPos, photo);
    });
  }

  /// 照片拖拽更新回调
  void _onPhotoDragUpdate(Offset globalPos) {
    if (_canvasPinching.value) return;
    if (!_photoDragHandler.isDragging) return;
    _canvasMotionNotifier.value++;

    final pos = _photoDragHandler.onDragUpdate(
        globalPos, _navigationHandler.canvasScale);
    if (pos == null) return;

    ref
        .read(photoListProvider.notifier)
        .updatePhotoPositionInMemory(
            _photoDragHandler.draggingPhotoId!, pos.dx, pos.dy);
  }

  /// 照片拖拽结束回调
  Future<void> _onPhotoDragEnd() async {
    final oldPos = _photoDragHandler.photoStartPos;
    final photoId = _photoDragHandler.onDragEnd();

    if (photoId != null) {
      await ref
          .read(photoListProvider.notifier)
          .persistPhotoPosition(photoId);

      final photo = ref.read(photoListProvider).value?.firstWhereOrNull(
            (p) => p.id == photoId,
          );
      if (photo != null) {
        final newPos = (photo.x, photo.y);
        if (oldPos.dx != newPos.$1 || oldPos.dy != newPos.$2) {
          ref.read(undoRedoProvider.notifier).executeCommand(
                MovePhotosCommand(
                  ref.read(photoListProvider.notifier),
                  {photoId: (oldPos.dx, oldPos.dy)},
                  {photoId: newPos},
                ),
              );
        }
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

  /// 选中一张卡片
  ///
  /// 将该卡片及其所有直接关联卡片加入高亮集合，
  /// 实现"选中即高亮关联网络"的视觉效果。
  void _selectCard(int cardId) {
    AppHaptics.light();
    final connections = ref.read(connectionListProvider).value ?? [];
    setState(() {
      _selection.selectCard(cardId, connections);
    });
  }

  /// 清除卡片/照片选中状态和高亮集合
  /// 删除当前选中的卡片或照片
  void _deleteSelected() {
    if (_selection.selectedCardId != null) {
      final cardId = _selection.selectedCardId!;
      final cards = ref.read(cardListProvider).value ?? [];
      final card = cards.firstWhereOrNull((c) => c.id == cardId);
      if (card != null) {
        final connections = ref.read(connectionListProvider).value ?? [];
        final relatedConnections = connections
            .where((c) =>
                c.fromCardId == cardId || c.toCardId == cardId)
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
      _clearSelection();
    } else if (_selection.selectedPhotoId != null) {
      final photoId = _selection.selectedPhotoId!;
      final photos = ref.read(photoListProvider).value ?? [];
      final photo = photos.firstWhereOrNull((p) => p.id == photoId);
      if (photo != null) {
        final connections = ref.read(connectionListProvider).value ?? [];
        final relatedConnections = connections
            .where((c) =>
                c.fromPhotoId == photoId || c.toPhotoId == photoId)
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
      _clearSelection();
    }
  }

  void _clearSelection() {
    if (!_selection.hasSelection) return;
    setState(() {
      _selection.clearSelection();
    });
  }

  /// 搜索输入变化处理
  void _onSearchChanged(
    String query,
    List<ClueCard> cards,
    List<PhotoCard> photos,
    List<Connection> connections,
  ) {
    _searchCtrl.updateQuery(query,
        cards: cards,
        photos: photos,
        connections: connections,
        onSearched: () {
      _searchCtrl.navigateToFirstResult(
        cards: cards,
        photos: photos,
        renderedConnections: ref.read(renderedConnectionsProvider),
        transformController: _transformController,
        zoomController: _zoomController,
        navigationHandler: _navigationHandler,
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

    return _ClueWallShortcuts(
      showSearch: _searchCtrl.showSearch,
      hasSelection: _selection.hasSelection,
      onCloseSearch: () {
        _searchCtrl.close();
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
              final isSearching = _searchCtrl.isSearching;
              final searchMatches = _searchCtrl.results;
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
                        connectionHandler: _connectionHandler,
                        updateConnecting: (pos) => _updateConnecting(pos),
                        isCardInteracting: () =>
                            _cardPointerDown.value || _dragHandler.isDragging,
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
                              highlightedConnectionIds: isSearching
                                  ? searchMatches.connectionIds
                                  : const {},
                            ),
                            // === 第 4 层：正在连线的动态线 ===
                            // 连线模式下从源卡片到手指位置的动态红线，
                            // IgnorePointer 避免阻挡下层交互
                            if (_connectionHandler.isConnecting)
                              IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _connectingAnimController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: const Size(
                                          WallConstants.canvasWidth,
                                          WallConstants.canvasHeight),
                                      painter: ConnectingLinePainter(
                                        from: _connectionHandler
                                            .connectingFromPos,
                                        to: _connectionHandler
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
                              SearchResultBadge(count: _searchCtrl.resultCount),
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
                    showSearch: _searchCtrl.showSearch,
                    searchController: _searchCtrl.textController,
                    cardCount: cards.length,
                    onSearchChanged: (query) =>
                        _onSearchChanged(query, cards, photos, connections),
                    onSearchToggle: () {
                      _searchCtrl.toggle();
                      setState(() {});
                    },
                  ),
                  if (_connectionHandler.isConnecting) const ConnectingHint(),
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

    for (final card in cards) {
      final isMatch =
          matchIds != null && matchIds.contains(card.id); // 是否匹配搜索结果
      final isFloating = card.id != null &&
          _selection.highlightedCardIds.contains(card.id!); // 是否需要浮动（选中/高亮）
      final isPrimary = card.id == _selection.selectedCardId; // 是否为当前选中的主卡片

      final widget = Positioned(
        left: card.x,
        top: card.y,
        child: RepaintBoundary(
          child: ClueCardWidget(
            key: ValueKey(card.id),
            card: card,
            scale: _navigationHandler.canvasScale,
            isConnectingTarget: _connectionHandler.isConnecting &&
                card.id !=
                    _connectionHandler
                        .connectingFromCardId, // 连线模式下非源卡片显示为可连接目标
            isHighlighted: isMatch,
            isFloating: isFloating,
            isPrimary: isPrimary,
            isCanvasPinching: _canvasPinching.value,
            onPointerDown: () => _cardPointerDown.value = true,
            onPointerUp: () => _cardPointerDown.value = false,
            onTap: () async {
              if (_connectionHandler.isConnecting && card.id != null) {
                await _tryConnect(toCardId: card.id!);
              } else if (card.id != null) {
                if (_selection.selectedCardId == card.id) {
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
              if (!_connectionHandler.isConnecting && !_canvasPinching.value) {
                _onCardDragStart(card.id!, globalPos);
              }
            },
            onDragUpdate: _onCardDragUpdate,
            onDragEnd: _onCardDragEnd,
            onPinLongPressStart: (globalPos) {
              if (!_connectionHandler.isConnecting && card.id != null) {
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

    for (final photo in photos) {
      final isMatch = matchIds != null && matchIds.contains(photo.id);
      final isPrimary = photo.id == _selection.selectedPhotoId;
      final isFloating = photo.id != null &&
          (_selection.selectedPhotoId == photo.id ||
              _selection.highlightedPhotoIds.contains(photo.id));

      final widget = Positioned(
        left: photo.x,
        top: photo.y,
        child: RepaintBoundary(
          child: PhotoCardWidget(
            key: ValueKey(photo.id),
            photo: photo,
            isPrimary: isPrimary,
            isHighlighted: isMatch || isFloating,
            isConnectingTarget: _connectionHandler.isConnecting &&
                photo.id != _connectionHandler.connectingFromPhotoId,
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
              if (_connectionHandler.isConnecting && photo.id != null) {
                await _tryConnect(toPhotoId: photo.id!);
              } else {
                setState(() {
                  if (_selection.selectedPhotoId == photo.id) {
                    _selection.selectedPhotoId = null;
                  } else {
                    _selection.selectPhoto(photo.id!);
                  }
                });
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
              if (!_connectionHandler.isConnecting && photo.id != null) {
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
