import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_model.dart';
import '../models/rendered_connection.dart';
import '../models/thread_pluck_event.dart';
import '../providers/connection_provider.dart';
import '../providers/connection_render_provider.dart';
import '../providers/relationship_filter_provider.dart';
import '../theme/wall_constants.dart';
import '../utils/thread_wave.dart';
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

  /// 是否处于关系网络聚焦模式
  final bool focusActive;

  /// 聚焦网络内的连线 ID
  final Set<int> focusConnectionIds;

  /// 长按拨动事件；null 表示不支持拨动（测试/降级场景）
  final ValueListenable<ThreadPluckEvent?>? pluckNotifier;

  const ThreadLayer({
    super.key,
    required this.canvasScaleNotifier,
    required this.canvasMotionNotifier,
    required this.connectionLabels,
    this.highlightedConnectionIds = const {},
    this.focusActive = false,
    this.focusConnectionIds = const {},
    this.pluckNotifier,
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
  final Map<int, List<Offset>> _baseMidpointSources = {};

  /// 正在执行渐入动画的连线 ID 集合
  final Set<int> _fadingInIds = {};

  /// 上一帧的连线 ID 集合，用于检测新增连线
  final Set<int> _previousConnectionIds = {};

  static const _idleDebounce = Duration(seconds: 2);
  static const _fadeInDuration = Duration(milliseconds: 400);

  /// 正在波动的连线：connectionId → 弦波状态
  final Map<int, ThreadWave> _waves = {};

  /// 等待延迟注入的邻居波（用于共享卡片传导）
  final List<_PendingImpulse> _pendingImpulses = [];

  /// 波动帧通知器，驱动 AnimatedBuilder 重绘而不重建整页
  final ValueNotifier<int> _waveTick = ValueNotifier(0);

  late final Ticker _waveTicker;
  Duration? _lastWaveElapsed;
  double _waveTimeAccumulator = 0;

  static const double _waveStepSeconds = 1 / 120;
  static const double _pluckAmplitude = 20;
  static const double _neighborAmplitudeRatio = 0.4;
  static const double _neighborDelaySeconds = 0.14;

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
    _waveTicker = createTicker(_onWaveTick);
    widget.canvasMotionNotifier.addListener(_handleCanvasMotion);
    widget.pluckNotifier?.addListener(_handlePluckEvent);
  }

  @override
  void didUpdateWidget(covariant ThreadLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canvasMotionNotifier != widget.canvasMotionNotifier) {
      oldWidget.canvasMotionNotifier.removeListener(_handleCanvasMotion);
      widget.canvasMotionNotifier.addListener(_handleCanvasMotion);
    }
    if (oldWidget.pluckNotifier != widget.pluckNotifier) {
      oldWidget.pluckNotifier?.removeListener(_handlePluckEvent);
      widget.pluckNotifier?.addListener(_handlePluckEvent);
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

  void _handlePluckEvent() {
    final event = widget.pluckNotifier?.value;
    if (event == null || !mounted) return;
    _pluck(event.connectionId, event.position, propagate: true);
  }

  /// 在指定连线的 [position] 处注入波动
  ///
  /// [propagate] 为 true 时，会向共享端点的邻居连线延迟注入衰减波。
  void _pluck(
    int connectionId,
    Offset position, {
    required bool propagate,
    double? amplitude,
    double? atT,
  }) {
    final rendered = ref.read(renderedConnectionsProvider);
    final conn =
        rendered.firstWhereOrNull((c) => c.connectionId == connectionId);
    if (conn == null || conn.points.length < 4) return;

    final t = atT ?? _nearestT(conn.points, position);
    final wave = _waves.putIfAbsent(connectionId, ThreadWave.new);
    wave.pluck(t, amplitude: amplitude ?? _pluckAmplitude);

    _startWaveTicker();

    if (propagate) {
      _scheduleNeighborWaves(
        conn,
        amplitude: amplitude ?? _pluckAmplitude,
      );
    }
    _waveTick.value++;
  }

  /// 找到触点在基础曲线上最近的位置（归一化 0~1）
  double _nearestT(List<Offset> points, Offset position) {
    const sampleCount = 30;
    final samples = RedThreadPainter.sampleBezier(points, sampleCount);
    if (samples.length < 2) return 0.5;

    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < samples.length; i++) {
      final distance = (samples[i] - position).distanceSquared;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex / (samples.length - 1);
  }

  /// 通过共享卡片/照片，把波动延迟传给相邻连线（只传导一跳）
  void _scheduleNeighborWaves(
    RenderedConnection conn, {
    required double amplitude,
  }) {
    final connections = ref.read(connectionListProvider).value;
    if (connections == null) return;

    final target =
        connections.firstWhereOrNull((c) => c.id == conn.connectionId);
    if (target == null) return;

    final endpoints = <int>{
      if (target.fromCardId != null) target.fromCardId!,
      if (target.toCardId != null) target.toCardId!,
      if (target.fromPhotoId != null) target.fromPhotoId!,
      if (target.toPhotoId != null) target.toPhotoId!,
    };

    var scheduled = 0;
    for (final other in connections) {
      if (other.id == null || other.id == target.id) continue;

      final sharesStart =
          (other.fromCardId != null && endpoints.contains(other.fromCardId)) ||
              (other.fromPhotoId != null &&
                  endpoints.contains(other.fromPhotoId));
      final sharesEnd =
          (other.toCardId != null && endpoints.contains(other.toCardId)) ||
              (other.toPhotoId != null && endpoints.contains(other.toPhotoId));
      if (!sharesStart && !sharesEnd) continue;

      _pendingImpulses.add(_PendingImpulse(
        connectionId: other.id!,
        t: sharesStart ? 0.04 : 0.96,
        amplitude: amplitude * _neighborAmplitudeRatio,
        remainingSeconds: _neighborDelaySeconds,
      ));
      scheduled++;
      if (scheduled >= 4) break;
    }
  }

  void _startWaveTicker() {
    if (_waveTicker.isActive) return;
    _lastWaveElapsed = null;
    _waveTimeAccumulator = 0;
    _waveTicker.start();
  }

  void _onWaveTick(Duration elapsed) {
    if (!mounted) return;
    final last = _lastWaveElapsed;
    _lastWaveElapsed = elapsed;
    if (last == null) return;

    final rawDt =
        (elapsed - last).inMicroseconds / Duration.microsecondsPerSecond;
    if (rawDt <= 0) return;
    final dt = rawDt > 0.05 ? 0.05 : rawDt;

    // 先处理延迟传导的邻居波
    for (final impulse in List<_PendingImpulse>.of(_pendingImpulses)) {
      impulse.remainingSeconds -= dt;
      if (impulse.remainingSeconds <= 0) {
        _pendingImpulses.remove(impulse);
        _pluck(
          impulse.connectionId,
          Offset.zero,
          propagate: false,
          amplitude: impulse.amplitude,
          atT: impulse.t,
        );
      }
    }

    // 固定 1/120s 子步进，保证不同帧率下波形一致
    _waveTimeAccumulator += dt;
    var steps = 0;
    while (_waveTimeAccumulator >= _waveStepSeconds && steps < 6) {
      for (final wave in _waves.values) {
        wave.step(_waveStepSeconds);
      }
      _waveTimeAccumulator -= _waveStepSeconds;
      steps++;
    }

    _waves.removeWhere((_, wave) => wave.isSettled);
    _waveTick.value++;

    if (_waves.isEmpty && _pendingImpulses.isEmpty) {
      _waveTicker.stop();
      _lastWaveElapsed = null;
      _waveTimeAccumulator = 0;
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
    widget.pluckNotifier?.removeListener(_handlePluckEvent);
    _waveTicker.dispose();
    _waveTick.dispose();
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
    final focusIds = widget.focusActive ? widget.focusConnectionIds : null;
    final visibleConnections = renderedConnections.where((conn) {
      final typeVisible = activeFilter.isEmpty ||
          activeFilter.contains(conn.connectionType) ||
          widget.highlightedConnectionIds.contains(conn.connectionId);
      final focusVisible =
          focusIds == null || focusIds.contains(conn.connectionId);
      return typeVisible && focusVisible;
    }).toList();

    return ValueListenableBuilder<double>(
      valueListenable: widget.canvasScaleNotifier,
      builder: (context, canvasScale, _) {
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _swayController,
              _motionController,
              _fadeInController,
              _waveTick,
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
                hint: '长按连线可拨动',
                child: CustomPaint(
                  size: const Size(
                      WallConstants.canvasWidth, WallConstants.canvasHeight),
                  painter: RedThreadPainter(
                    connections: renderedConnections,
                    scale: canvasScale,
                    connectionLabels: widget.connectionLabels,
                    highlightedIds: widget.highlightedConnectionIds,
                    activeFilter: activeFilter,
                    focusActive: widget.focusActive,
                    focusConnectionIds: widget.focusConnectionIds,
                    waveDisplacements: _waves.isEmpty
                        ? const <int, List<double>>{}
                        : {
                            for (final entry in _waves.entries)
                              entry.key: entry.value.displacements,
                          },
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
      // 卡片拖动后控制点会变化，中点缓存必须跟着更新，否则标签滞后
      final cachedPoints = _baseMidpointSources[conn.connectionId];
      if (cachedPoints == null || !_pointsEqual(cachedPoints, conn.points)) {
        _baseMidpoints[conn.connectionId] =
            RedThreadPainter.computeMidpoint(conn.points);
        _baseMidpointSources[conn.connectionId] = List<Offset>.of(conn.points);
      }
    }
    // 清除已不存在的连接的中点缓存
    _baseMidpoints.removeWhere((id, _) => !activeIds.contains(id));
    _baseMidpointSources.removeWhere((id, _) => !activeIds.contains(id));
    _labelCache.evictStale(activeIds);
  }

  static bool _pointsEqual(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 延迟注入的邻居波
class _PendingImpulse {
  final int connectionId;
  final double t;
  final double amplitude;
  double remainingSeconds;

  _PendingImpulse({
    required this.connectionId,
    required this.t,
    required this.amplitude,
    required this.remainingSeconds,
  });
}
