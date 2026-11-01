import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 渲染后的连接线数据
///
/// 每条红线的几何信息，包含 4 个贝塞尔控制点，
/// 供 [RedThreadPainter] 绘制三阶贝塞尔曲线。
class RenderedConnection extends Equatable {
  /// 连接的唯一标识，对应 Connection.id
  final int connectionId;

  /// 贝塞尔曲线的关键点列表
  ///
  /// 固定包含 4 个 [Offset]：
  /// - `points[0]`：起点图钉位置
  /// - `points[1]`：第一控制点（靠近起点，含下垂偏移）
  /// - `points[2]`：第二控制点（靠近终点，含下垂偏移）
  /// - `points[3]`：终点图钉位置
  final List<Offset> points;

  /// 连接线的张力值（0.0 ~ 3.0）
  final double tension;

  const RenderedConnection({
    required this.connectionId,
    required this.points,
    this.tension = 0,
  });

  /// 轴对齐包围盒（AABB），由 4 个控制点的极值构成。
  ///
  /// 贝塞尔曲线始终位于控制点凸包内部，因此控制点的 AABB
  /// 是曲线的保守包围盒，可用于快速排除不可命中的连接。
  Rect get bounds {
    if (points.isEmpty) return Rect.zero;
    double minX = points[0].dx, maxX = points[0].dx;
    double minY = points[0].dy, maxY = points[0].dy;
    for (int i = 1; i < points.length; i++) {
      final p = points[i];
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  List<Object?> get props => [connectionId, tension, ...points];
}
