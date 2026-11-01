/// 侦探线索墙 —— 红线绘制器
///
/// 在侦探风格的软木板上，线索卡片之间用红色棉线相连，是经典"线索墙"的标志性视觉元素。
/// 本文件实现了 [RedThreadPainter]，负责将所有线索连接以逼真的红线效果渲染到 Canvas 上。
///
/// 渲染层次（从底到顶）：
/// 1. **阴影层** [_drawShadow] —— 模拟红线在软木板上的投影，偏移 + 模糊
/// 2. **主线层** [_drawThread] —— 红色主线 + 偏移高光线，模拟棉线的立体感
/// 3. **绳结层** [_drawKnots] —— 线段两端绘制绳结，使用径向渐变呈现球状立体感
/// 4. **标签层** [_drawLabel] —— 在线段中点绘制连接标签（如关系描述），带仿旧纸背景
///
/// 此外还提供了 [hitTestConnection] 用于点击检测，以及 [_sampleBezier] / [_cubicBezier]
/// 用于贝塞尔曲线采样，支撑命中测试和标签定位。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/clue_type_style.dart';
import '../../models/connection_model.dart';
import '../../models/rendered_connection.dart';

/// 红线绘制器 —— CustomPainter 实现
///
/// 接收 [RenderedConnection] 列表，对每条连接依次绘制阴影→主线→绳结→标签。
/// 所有线宽均根据 [scale]（画布缩放比例）进行反比校正，确保在不同缩放级别下视觉粗细一致。
class RedThreadPainter extends CustomPainter {
  /// 需要绘制的连接列表，每条连接包含控制点和连接 ID
  final List<RenderedConnection> connections;

  /// 当前画布缩放比例，用于反比校正线宽，使缩放后线条粗细保持视觉一致
  final double scale;

  /// 连接标签映射表：connectionId → 标签文字（如"同事"、"嫌疑人"等关系描述）
  final Map<int, String?> connectionLabels;

  /// 需要高亮显示的连接 ID 集合（搜索匹配结果）
  final Set<int> highlightedIds;

  /// 当前关系类型筛选；空集合表示不筛选
  ///
  /// 不在集合中的连线会以极低透明度绘制，不显示标签，也不参与命中。
  final Set<ConnectionType> activeFilter;

  /// 摆动时间参数（弧度），用于驱动红线的轻微水平摆动动画
  final double swayTime;

  /// Sway amplitude multiplier.
  final double swayStrength;

  /// 标签布局缓存（由 ThreadLayer 持有生命周期），避免每帧重新 layout TextPainter
  final LabelLayoutCache? labelCache;

  /// 预计算的未摆动贝塞尔中点（connectionId → midpoint），由 ThreadLayer 缓存
  final Map<int, Offset>? baseMidpoints;

  /// 连线渐入透明度映射（connectionId → opacity 0.0~1.0）
  /// 不在 map 中的连接使用默认 1.0 不透明
  final Map<int, double>? fadeOpacities;

  RedThreadPainter({
    required this.connections,
    required this.scale,
    required this.connectionLabels,
    this.highlightedIds = const {},
    this.activeFilter = const {},
    this.swayTime = 0,
    this.swayStrength = 1,
    this.labelCache,
    this.baseMidpoints,
    this.fadeOpacities,
  });

  /// 计算三次贝塞尔曲线在 t=0.5 处的中点
  static Offset computeMidpoint(List<Offset> points) {
    if (points.length < 4) return points.first;
    return _cubicBezier(points[0], points[1], points[2], points[3], 0.5);
  }

  /// 命中测试 —— 判断点击位置是否在某条红线的附近
  ///
  /// 算法：对每条连接的贝塞尔曲线进行离散采样（24个采样点），
  /// 然后检查点击位置与每个采样点的距离是否小于 [threshold]。
  /// 返回命中的连接 ID，未命中则返回 null。
  ///
  /// 之所以用采样法而非 Path 精确命中，是因为 CustomPainter 的 hitTest
  /// 不支持描边路径的精确距离计算，采样法在性能和精度之间取得了良好平衡。
  static int? hitTestConnection(
    Offset point,
    List<RenderedConnection> connections,
    double threshold,
  ) {
    // 命中区域扩展为 Rect，用于 AABB 预过滤
    final hitRect = Rect.fromCenter(
      center: point,
      width: threshold * 2,
      height: threshold * 2,
    );
    for (final conn in connections) {
      // 至少需要 4 个点（起点、两个控制点、终点）才能构成三次贝塞尔曲线
      if (conn.points.length < 4) continue;
      // AABB 预过滤：若命中区域与连接包围盒不相交，跳过采样
      if (!conn.bounds.overlaps(hitRect)) continue;
      final samples = _sampleBezier(conn.points, 24);
      for (final sample in samples) {
        if ((point - sample).distance < threshold) {
          return conn.connectionId;
        }
      }
    }
    return null;
  }

  /// 对三次贝塞尔曲线进行均匀参数采样
  ///
  /// 将 t ∈ [0, 1] 均匀分为 [count] 段，计算每个参数值对应的曲线点。
  /// 用于命中测试和标签中点定位。
  ///
  /// 注意：这是参数空间的均匀采样，不是弧长均匀采样。
  /// 在控制点距离差异较大时，采样点在曲线上的分布可能不均匀，
  /// 但对于命中测试和标签定位的精度需求已经足够。
  static List<Offset> _sampleBezier(List<Offset> points, int count) {
    if (points.length < 4) return points;

    final from = points[0];
    final cp1 = points[1];
    final cp2 = points[2];
    final to = points[3];

    final result = <Offset>[];
    for (int i = 0; i <= count; i++) {
      final t = i / count;
      result.add(_cubicBezier(from, cp1, cp2, to, t));
    }
    return result;
  }

  /// 三次贝塞尔曲线公式
  ///
  /// B(t) = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
  ///
  /// 其中 P₀ 为起点，P₁/P₂ 为控制点，P₃ 为终点。
  /// 这是 De Casteljau 算法在三次情况下的直接展开。
  static Offset _cubicBezier(
      Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    return Offset(
      u * u * u * p0.dx +
          3 * u * u * t * p1.dx +
          3 * u * t * t * p2.dx +
          t * t * t * p3.dx,
      u * u * u * p0.dy +
          3 * u * u * t * p1.dy +
          3 * u * t * t * p2.dy +
          t * t * t * p3.dy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final conn in connections) {
      if (conn.points.length < 4) continue;
      final opacity = fadeOpacities?[conn.connectionId] ?? 1.0;
      if (opacity <= 0) continue;

      canvas.save();
      final isHighlighted = highlightedIds.contains(conn.connectionId);
      final swayedConn = _applySway(conn);
      final isFilteredOut = activeFilter.isNotEmpty &&
          !activeFilter.contains(conn.connectionType);
      if (isFilteredOut && !isHighlighted) {
        _drawDimmedThread(canvas, swayedConn, opacity);
        canvas.restore();
        continue;
      }
      if (isHighlighted) _drawGlow(canvas, swayedConn, opacity);
      _drawShadow(canvas, swayedConn, opacity);
      _drawThread(canvas, swayedConn,
          isHighlighted: isHighlighted, opacity: opacity);
      _drawKnots(canvas, swayedConn, opacity);
      _drawLabel(canvas, swayedConn, originalConn: conn, opacity: opacity);
      canvas.restore();
    }
  }

  /// 绘制被筛选淡化的连线
  ///
  /// 只画一条低透明度主线，不画阴影、绳结和标签，
  /// 既保留整体关系结构，又让当前筛选类型成为视觉焦点。
  void _drawDimmedThread(
    Canvas canvas,
    RenderedConnection conn,
    double opacity,
  ) {
    final path = _buildPath(conn.points);
    final width = (1.1 / scale).clamp(0.7, 2.0);
    final palette = conn.connectionType.palette;

    canvas.drawPath(
      path,
      Paint()
        ..color = palette.base.withValues(alpha: 0.12 * opacity)
        ..strokeWidth = width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  /// 每条连线独立的相位偏移，使不同连线摆动不同步
  double _swayPhase(int connectionId) =>
      (connectionId * 1.7) % (2 * math.pi);

  /// 对连接的控制点施加轻微水平摆动
  ///
  /// 每条连线有独立的相位（基于 connectionId），摆动幅度随距离端点越远越大。
  /// 端点（起点和终点）不受摆动影响，保持固定在图钉位置。
  RenderedConnection _applySway(RenderedConnection conn) {
    if (swayTime == 0 || swayStrength <= 0) return conn;

    // 每条连线独立的相位偏移，使不同连线摆动不同步
    final phase = _swayPhase(conn.connectionId);
    // 摆动幅度：控制点偏移 ±1.2px
    final amplitude = 1.2 * swayStrength;
    final offset = math.sin(swayTime + phase) * amplitude;

    // 起点和终点不变，两个控制点施加偏移
    // 中间控制点偏移更大，营造自然弧度变化
    final points = conn.points;
    final swayedPoints = [
      points[0], // 起点不变
      Offset(points[1].dx + offset * 0.6, points[1].dy),
      Offset(points[2].dx + offset, points[2].dy),
      points[3], // 终点不变
    ];

    return RenderedConnection(
      connectionId: conn.connectionId,
      points: swayedPoints,
      tension: conn.tension,
      connectionType: conn.connectionType,
    );
  }

  /// 绘制高亮光晕 —— 搜索匹配时在红线上叠加橙色光晕
  void _drawGlow(Canvas canvas, RenderedConnection conn, double opacity) {
    final path = _buildPath(conn.points);
    final width = (6.0 / scale).clamp(3.0, 10.0);

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.tagOrange.withValues(alpha: 0.25 * opacity)
        ..strokeWidth = width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 / scale),
    );
  }

  /// 根据控制点列表构建 Path
  ///
  /// 若点数 ≥ 4，构建三次贝塞尔曲线路径（起点 + cubicTo）；
  /// 否则退化为折线路径（moveTo + lineTo），作为降级处理。
  Path _buildPath(List<Offset> points) {
    if (points.length < 4) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      return path;
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    path.cubicTo(
      points[1].dx,
      points[1].dy,
      points[2].dx,
      points[2].dy,
      points[3].dx,
      points[3].dy,
    );
    return path;
  }

  /// 绘制阴影层
  ///
  /// 将路径向右下偏移 (1.5, 3.0) 像素，绘制一条比主线更粗的半透明黑色描边，
  /// 模拟红线在软木板上的投影效果。使用 StrokeCap.round 使阴影端点圆滑。
  void _drawShadow(Canvas canvas, RenderedConnection conn, double opacity) {
    final path = _buildPath(conn.points);
    final width = (2.0 / scale).clamp(1.0, 3.5);

    canvas.save();
    canvas.translate(1.5, 3.0);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15 * opacity)
        ..strokeWidth = width + 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  /// 绘制主线层 —— 棉线 + 高光偏移线
  ///
  /// 分两步绘制：
  /// 1. 主线：按关系类型使用对应棉线色（中立红/盟友绿/敌对黑/自定义蓝）
  /// 2. 高光线：将路径向左上偏移 (-0.3, -0.4)，用更细的半透明浅色描边，
  ///    模拟棉线受光面的高光反射，营造立体质感。
  ///
  /// 设计考量：真实棉线并非均匀着色，受光面会偏亮。通过偏移绘制细高光线，
  /// 在不使用 ImageShader 纹理的情况下也能呈现基本的纤维质感。
  void _drawThread(Canvas canvas, RenderedConnection conn,
      {bool isHighlighted = false, double opacity = 1.0}) {
    final path = _buildPath(conn.points);
    final width = (2.0 / scale).clamp(1.0, 3.5);
    final palette = conn.connectionType.palette;

    // 绘制主线，高亮时使用更亮的同色系
    final baseColor = isHighlighted ? palette.light : palette.base;
    canvas.drawPath(
      path,
      Paint()
        ..color = baseColor.withValues(alpha: baseColor.a * opacity)
        ..strokeWidth = isHighlighted ? width * 1.3 : width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 绘制偏移高光线，模拟棉线受光面的亮部
    canvas.save();
    canvas.translate(-0.3, -0.4);
    canvas.drawPath(
      path,
      Paint()
        ..color = palette.light.withValues(alpha: 0.18 * opacity)
        ..strokeWidth = (width * 0.35).clamp(0.3, 1.0)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  /// 绘制绳结层 —— 线段两端的装饰性绳结
  ///
  /// 在每条连接的起点和终点各绘制一个绳结，分两步：
  /// 1. 阴影圆：偏移绘制半透明黑色圆，模拟绳结投影
  /// 2. 主体圆：使用径向渐变（浅红→红→深红），渐变中心偏左上 (-0.3, -0.3)，
  ///    模拟球体的光照效果，使绳结呈现立体球状感。
  void _drawKnots(Canvas canvas, RenderedConnection conn, double opacity) {
    final points = conn.points;
    final knotRadius = (2.5 / scale).clamp(1.5, 4.0);
    final palette = conn.connectionType.palette;

    for (final point in [points.first, points.last]) {
      // 绳结投影
      canvas.drawCircle(
        Offset(point.dx + 0.8, point.dy + 1.5),
        knotRadius,
        Paint()..color = Colors.black.withValues(alpha: 0.12 * opacity),
      );

      // 绳结主体：径向渐变模拟球体光照
      canvas.drawCircle(
        point,
        knotRadius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 1.0,
            colors: [
              palette.light.withValues(alpha: palette.light.a * opacity),
              palette.base.withValues(alpha: palette.base.a * opacity),
              palette.dark.withValues(alpha: palette.dark.a * opacity),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: point, radius: knotRadius)),
      );
    }
  }

  /// 绘制标签层 —— 在线段中点显示连接关系标签
  ///
  /// 标签渲染流程：
  /// 1. 对贝塞尔曲线采样 20 个点，取中间点作为标签位置
  /// 2. 绘制标签背景：仿旧纸色圆角矩形，带轻微阴影和棕褐色描边
  /// 3. 在背景上居中绘制标签文字
  ///
  /// 视觉设计：标签背景使用 [AppColors.agedPaper]（仿旧纸张色），
  /// 描边使用 [AppColors.sepia]（棕褐色），与侦探主题的复古风格统一。
  void _drawLabel(Canvas canvas, RenderedConnection conn, {RenderedConnection? originalConn, double opacity = 1.0}) {
    final label = connectionLabels[conn.connectionId];
    if (label == null || label.isEmpty) return;

    // 计算标签中点：优先使用缓存的 baseMidpoint + 摆动偏移
    Offset mid;
    if (baseMidpoints != null && baseMidpoints!.containsKey(conn.connectionId)) {
      final baseMid = baseMidpoints![conn.connectionId]!;
      if (swayTime != 0 && swayStrength > 0) {
        final phase = _swayPhase(conn.connectionId);
        final amplitude = 1.2 * swayStrength;
        final swayOffset = math.sin(swayTime + phase) * amplitude;
        mid = Offset(baseMid.dx + swayOffset * 0.375, baseMid.dy);
      } else {
        mid = baseMid;
      }
    } else {
      mid = computeMidpoint(conn.points);
    }

    // 获取缓存的 TextPainter（避免每帧重新 layout）
    final TextPainter textPainter;
    if (labelCache != null) {
      final cacheKeyPoints = (originalConn ?? conn).points;
      textPainter = labelCache!.get(conn.connectionId, label, cacheKeyPoints, scale).textPainter;
    } else {
      final textStyle = TextStyle(
        color: AppColors.inkBlack.withValues(alpha: 0.7 * opacity),
        fontSize: (9 / scale).clamp(6.5, 12.0),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        fontFamily: AppTypography.harmonyOS,
      );
      textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
    }

    // 标签背景尺寸：关系类型圆点 + 间距 + 文字
    final padding = 3.5 / scale;
    final palette = conn.connectionType.palette;
    final dotRadius = (2.0 / scale).clamp(1.0, 3.0);
    final dotGap = 3.0 / scale;
    final dotDiameter = dotRadius * 2;
    final tagW = textPainter.width + padding * 2 + 5.0 / scale + dotDiameter + dotGap;
    final tagH = textPainter.height + padding * 2;
    final tagR = 2.0 / scale;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: mid, width: tagW, height: tagH),
      Radius.circular(tagR),
    );

    // 标签背景阴影
    canvas.drawRRect(
      bgRect.shift(const Offset(0.5, 1)),
      Paint()..color = Colors.black.withValues(alpha: 0.05 * opacity),
    );

    // 标签背景主体：仿旧纸色
    canvas.drawRRect(
      bgRect,
      Paint()..color = AppColors.agedPaper.withValues(alpha: 0.88 * opacity),
    );

    // 标签背景描边：关系类型色，弱化但可辨
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = palette.base.withValues(alpha: 0.3 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5 / scale,
    );

    // 关系类型圆点：让连线类型在标签旁始终可见
    canvas.drawCircle(
      Offset(bgRect.left + padding + dotRadius, mid.dy),
      dotRadius,
      Paint()..color = palette.base.withValues(alpha: 0.9 * opacity),
    );

    // 绘制标签文字，整体右移为类型圆点留出空间
    textPainter.paint(
      canvas,
      Offset(
        bgRect.left + padding + dotDiameter + dotGap,
        mid.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant RedThreadPainter oldDelegate) {
    if (scale != oldDelegate.scale ||
        connectionLabels != oldDelegate.connectionLabels ||
        highlightedIds != oldDelegate.highlightedIds ||
        activeFilter != oldDelegate.activeFilter ||
        swayTime != oldDelegate.swayTime ||
        swayStrength != oldDelegate.swayStrength ||
        fadeOpacities != oldDelegate.fadeOpacities ||
        connections.length != oldDelegate.connections.length) {
      return true;
    }
    for (int i = 0; i < connections.length; i++) {
      if (connections[i] != oldDelegate.connections[i]) {
        return true;
      }
    }
    return false;
  }
}

/// 标签布局缓存 —— 避免每帧为每条连线重新创建 TextPainter 和计算贝塞尔中点
///
/// 由 ThreadLayer 持有生命周期，跨帧复用。当 connectionLabels 或 connections
/// 数据变化时自动失效重建。
class LabelLayoutCache {
  final Map<int, CachedLabelEntry> _cache = {};

  /// 获取缓存的标签布局，若缓存失效则重新计算
  CachedLabelEntry get(
      int connectionId, String label, List<Offset> points, double scale) {
    final cached = _cache[connectionId];
    if (cached != null &&
        cached.label == label &&
        cached.scale == scale &&
        _pointsEqual(cached.points, points)) {
      return cached;
    }
    final mid = RedThreadPainter.computeMidpoint(points);
    final textStyle = TextStyle(
      color: AppColors.inkBlack.withValues(alpha: 0.7),
      fontSize: (9 / scale).clamp(6.5, 12.0),
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      fontFamily: AppTypography.harmonyOS,
    );
    final tp = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final entry = CachedLabelEntry(
      label: label,
      points: points,
      scale: scale,
      midpoint: mid,
      textPainter: tp,
    );
    // 释放旧的 TextPainter
    cached?.textPainter.dispose();
    _cache[connectionId] = entry;
    return entry;
  }

  /// 清除不再存在的连接的缓存条目
  void evictStale(Set<int> activeIds) {
    final staleIds = _cache.keys.where((id) => !activeIds.contains(id)).toList();
    for (final id in staleIds) {
      _cache.remove(id)?.textPainter.dispose();
    }
  }

  /// 清除全部缓存
  void clear() {
    for (final entry in _cache.values) {
      entry.textPainter.dispose();
    }
    _cache.clear();
  }

  static bool _pointsEqual(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class CachedLabelEntry {
  final String label;
  final List<Offset> points;
  final double scale;
  final Offset midpoint;
  final TextPainter textPainter;

  const CachedLabelEntry({
    required this.label,
    required this.points,
    required this.scale,
    required this.midpoint,
    required this.textPainter,
  });
}
