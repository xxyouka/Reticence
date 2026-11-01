import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/wall_constants.dart';

/// 连线动画绘制器
///
/// 在用户从图钉拖拽创建连线时，绘制从源卡片到手指位置的动态红线。
/// 绘制效果包含多个层次，模拟真实红线的视觉质感：
/// 1. **阴影层**：偏移绘制模糊的暗色路径，营造立体感
/// 2. **主线层**：红色主线，半透明
/// 3. **高光层**：细微的亮色偏移线，模拟光线反射
/// 4. **终点光晕**：径向渐变圆点，提示连线目标位置
/// 5. **外圈光晕**：更大范围的淡色圆，增强光晕效果
/// 6. **起点绳结**：径向渐变的圆点，模拟红线在图钉上的绳结
///
/// 线条使用两段二次贝塞尔曲线绘制，中间带有下垂量（sag），
/// 模拟真实红线的重力下垂效果。下垂量与线段长度成正比。
/// [opacity] 参数控制连线的淡入动画进度（0→1），
/// 线条终点从起点向实际终点渐变延伸。
class ConnectingLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final double opacity;

  ConnectingLinePainter({
    required this.from,
    required this.to,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final effectiveTo = Offset(
      from.dx + (to.dx - from.dx) * opacity,
      from.dy + (to.dy - from.dy) * opacity,
    );

    final dx = (effectiveTo.dx - from.dx).abs();
    final dy = (effectiveTo.dy - from.dy).abs();
    final dist = sqrt(dx * dx + dy * dy);
    final sag = dist * WallConstants.connectingLineSagFactor + WallConstants.connectingLineMinSag;

    final midX = (from.dx + effectiveTo.dx) / 2;
    final midY = (from.dy + effectiveTo.dy) / 2 + sag;

    final path = Path();
    path.moveTo(from.dx, from.dy);
    path.quadraticBezierTo(
      from.dx + (midX - from.dx) * 0.5,
      from.dy + sag * 0.7,
      midX,
      midY,
    );
    path.quadraticBezierTo(
      effectiveTo.dx - (effectiveTo.dx - midX) * 0.5,
      effectiveTo.dy + sag * 0.7,
      effectiveTo.dx,
      effectiveTo.dy,
    );

    // 第 1 层：阴影
    canvas.save();
    canvas.translate(1.5, 3);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12 * opacity)
      ..strokeWidth = WallConstants.connectingLineShadowWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, WallConstants.connectingLineShadowBlur);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 第 2 层：红色主线
    final paint = Paint()
      ..color = AppColors.redThread.withValues(alpha: 0.7 * opacity)
      ..strokeWidth = WallConstants.connectingLineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    // 第 3 层：高光线
    final highlightPaint = Paint()
      ..color = AppColors.redThreadLight.withValues(alpha: 0.15 * opacity)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(-0.2, -0.4);
    canvas.drawPath(path, highlightPaint);
    canvas.restore();

    // 第 4 层：终点光晕
    final dotPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.redThreadLight.withValues(alpha: opacity),
          AppColors.redThread.withValues(alpha: 0.5 * opacity),
        ],
      ).createShader(Rect.fromCircle(center: effectiveTo, radius: 7));
    canvas.drawCircle(effectiveTo, WallConstants.connectingLineDotRadius, dotPaint);

    // 第 5 层：外圈光晕
    final glowPaint = Paint()
      ..color = AppColors.redThread.withValues(alpha: 0.10 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(effectiveTo, WallConstants.connectingLineGlowRadius, glowPaint);

    // 第 6 层：起点绳结
    final knotPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [
          AppColors.redThreadLight,
          AppColors.redThread,
          AppColors.redThreadDark,
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: from, radius: 3));
    canvas.drawCircle(from, WallConstants.connectingLineKnotRadius, knotPaint);
  }

  @override
  bool shouldRepaint(covariant ConnectingLinePainter oldDelegate) {
    return from != oldDelegate.from ||
        to != oldDelegate.to ||
        opacity != oldDelegate.opacity;
  }
}
