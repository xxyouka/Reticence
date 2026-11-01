import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_model.dart';
import '../models/rendered_connection.dart';
import '../providers/connection_render_provider.dart';
import '../providers/relationship_filter_provider.dart';
import '../theme/wall_constants.dart';
import '../widgets/painters/red_thread_painter.dart';

/// 红线连接渲染层
///
/// 使用 [RedThreadPainter] 在画布上绘制所有红线连接。
/// 整个层包裹在 [IgnorePointer] 中，使触摸事件穿透到下层的卡片，
/// 同时使用 [RepaintBoundary] 隔离重绘范围以优化性能。
///
/// 红线有轻微的水平摆动动画，模拟风吹过绳子的效果。
class ThreadLayer extends ConsumerStatefulWidget {
  final ValueNotifier<double> canvasScaleNotifier;
  final ValueNotifier<int> canvasMotionNotifier;
  final Map<int, String?> connectionLabels;
  final Set<int> highlightedConnectionIds;

  const ThreadLayer({
    super.key,
    required this.canvasScaleNotifier,
    required this.canvasMotionNotifier,
    required this.connectionLabels,
    this.highlightedConnectionIds = const {},
  });

  @override
  ConsumerState<ThreadLayer> createState() => _ThreadLayerState();
}

class _ThreadLayerState extends ConsumerState<ThreadLayer>
    with TickerProviderStateMixin {
  late final AnimationController _swayController;
  late final AnimationController _motionController;
  late final AnimationController _fadeInController;
  Timer? _idleTimer;
  bool _isSwayActive = false;
  final _labelCache = LabelLayoutCache();
  final Map<int, Offset> _baseMidpoints = {};

  /// 正在执行渐入动画的连线 ID 集合
  final Set<int> _fadingInIds = {};

  /// 上一帧的连线 ID 集合，用于检测新增连线
  final Set<int> _previousConnectionIds = {};

  static const _idleDebounce = Duration(seconds: 2);
  static const _fadeInDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _motionController = AnimationController(
      duration: const Duration(milliseconds: 720),
      vsync: this,
    )..value = 1.0;
    _motionController.addStatusListener(_onMotionStatus);
    _fadeInController = AnimationController(
      duration: _fadeInDuration,
      vsync: this,
    );
    _fadeInController.addStatusListener(_onFadeInStatus);
    widget.canvasMotionNotifier.addListener(_handleCanvasMotion);
  }

  @override
  void didUpdateWidget(covariant ThreadLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canvasMotionNotifier != widget.canvasMotionNotifier) {
      oldWidget.canvasMotionNotifier.removeListener(_handleCanvasMotion);
      widget.canvasMotionNotifier.addListener(_handleCanvasMotion);
    }
  }

  void _handleCanvasMotion() {
    if (!mounted) return;
    _idleTimer?.cancel();
    _idleTimer = null;
    if (!_isSwayActive) {
      _isSwayActive = true;
      _swayController.repeat();
    }
    if (!_motionController.isAnimating) {
      _motionController.forward(from: 0);
    }
  }

  void _onMotionStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _idleTimer?.cancel();
      _idleTimer = Timer(_idleDebounce, _stopSwayIfIdle);
    }
  }

  void _stopSwayIfIdle() {
    if (!mounted) return;
    _isSwayActive = false;
    _swayController.stop();
  }

  void _onFadeInStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _fadingInIds.clear();
      });
      _fadeInController.reset();
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _labelCache.clear();
    widget.canvasMotionNotifier.removeListener(_handleCanvasMotion);
    _motionController.removeStatusListener(_onMotionStatus);
    _motionController.dispose();
    _fadeInController.removeStatusListener(_onFadeInStatus);
    _fadeInController.dispose();
    _swayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderedConnections = ref.watch(renderedConnectionsProvider);
    final activeFilter = ref.watch(relationshipFilterProvider);

    // 预计算未摆动的贝塞尔中点（仅当连接数据变化时更新）
    _updateBaseMidpoints(renderedConnections);

    // 检测新增连线并触发渐入动画
    _detectNewConnections(renderedConnections);

    // 语义层只统计当前可见/搜索命中的连线，避免朗读被淡化或隐藏的线
    final visibleConnections = activeFilter.isEmpty
        ? renderedConnections
        : renderedConnections
            .where((conn) =>
                activeFilter.contains(conn.connectionType) ||
                widget.highlightedConnectionIds.contains(conn.connectionId))
            .toList();

    return ValueListenableBuilder<double>(
      valueListenable: widget.canvasScaleNotifier,
      builder: (context, canvasScale, _) {
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _swayController,
              _motionController,
              _fadeInController,
            ]),
            builder: (context, _) {
              final motionImpulse =
                  1 - Curves.easeOutCubic.transform(_motionController.value);
              final swayStrength = 0.14 + motionImpulse * 0.9;
              // 在 AnimatedBuilder 内部构建透明度，确保每帧更新
              final fadeOpacities = _buildFadeOpacities();
              return Semantics(
                label: _buildConnectionSemanticsLabel(
                  visibleConnections,
                  activeFilter,
                ),
                child: CustomPaint(
                  size: const Size(
                      WallConstants.canvasWidth, WallConstants.canvasHeight),
                  painter: RedThreadPainter(
                    connections: renderedConnections,
                    scale: canvasScale,
                    connectionLabels: widget.connectionLabels,
                    highlightedIds: widget.highlightedConnectionIds,
                    activeFilter: activeFilter,
                    swayTime: _swayController.value * 2 * math.pi,
                    swayStrength: swayStrength,
                    labelCache: _labelCache,
                    baseMidpoints: _baseMidpoints,
                    fadeOpacities: fadeOpacities,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建连线层的无障碍标签
  String _buildConnectionSemanticsLabel(
    List<RenderedConnection> visibleConnections,
    Set<ConnectionType> activeFilter,
  ) {
    final labels = visibleConnections
        .map((conn) => widget.connectionLabels[conn.connectionId])
        .whereType<String>()
        .where((label) => label.isNotEmpty)
        .toList();
    final filterSuffix = activeFilter.isEmpty
        ? ''
        : '，筛选：${activeFilter.map((type) => type.label).join('、')}';
    if (labels.isEmpty) {
      return '${visibleConnections.length} 条连线$filterSuffix';
    }
    final preview = labels.take(3).join('、');
    final suffix = labels.length > 3 ? '等' : '';
    return '${visibleConnections.length} 条连线$filterSuffix：$preview$suffix';
  }

  /// 检测新增连线，将其加入渐入动画集合
  void _detectNewConnections(List<RenderedConnection> connections) {
    final currentIds = connections.map((c) => c.connectionId).toSet();
    final newIds = currentIds.difference(_previousConnectionIds);
    if (newIds.isNotEmpty) {
      _fadingInIds.addAll(newIds);
      _fadeInController.forward(from: 0);
    }
    _previousConnectionIds
      ..clear()
      ..addAll(currentIds);
  }

  /// 构建连线渐入透明度映射
  Map<int, double>? _buildFadeOpacities() {
    if (_fadingInIds.isEmpty) return null;
    final opacity = Curves.easeOut.transform(_fadeInController.value);
    return {for (final id in _fadingInIds) id: opacity};
  }

  void _updateBaseMidpoints(List<RenderedConnection> connections) {
    final activeIds = <int>{};
    for (final conn in connections) {
      if (conn.points.length < 4) continue;
      activeIds.add(conn.connectionId);
      // 仅当连接 ID 不在缓存中时才重新计算中点
      if (!_baseMidpoints.containsKey(conn.connectionId)) {
        _baseMidpoints[conn.connectionId] =
            RedThreadPainter.computeMidpoint(conn.points);
      }
    }
    // 清除已不存在的连接的中点缓存
    _baseMidpoints.removeWhere((id, _) => !activeIds.contains(id));
    _labelCache.evictStale(activeIds);
  }
}
