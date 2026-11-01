/// 侦探线索墙 —— 图钉装饰器
///
/// 图钉是线索墙的标志性视觉元素，用于将卡片和照片"钉"在软木板上。
/// 本文件实现了逼真的图钉渲染，包括：
/// - 径向渐变的塑料钉帽（模拟球面光照）
/// - 金属质感的钉尖（中心高光 + 暗色边缘）
/// - 投影效果（模糊阴影）
/// - 高光反射（左上角亮斑）
/// - 钉帽边缘描边（增强轮廓感）
/// - 按压缩放 + 阴影变化微交互动画
///
/// 渲染层次（从底到顶）：
/// 1. 阴影 → 2. 钉帽主体 → 3. 钉帽边缘 → 4. 高光 → 5. 钉尖 → 6. 钉尖边缘
library;

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/wall_constants.dart';

/// 图钉装饰组件 —— StatefulWidget
///
/// 使用 [CustomPaint] + [_PushpinPainter] 渲染逼真的图钉。
/// 支持按压缩放动画（[isPressed] 为 true 时缩小到 0.92）。
/// 可通过 [color] 参数自定义钉帽颜色，默认为 [AppColors.pinRed]。
class Pushpin extends StatefulWidget {
  /// 钉帽颜色
  final Color color;

  /// 是否处于按压状态
  final bool isPressed;

  const Pushpin({
    super.key,
    this.color = AppColors.pinRed,
    this.isPressed = false,
  });

  @override
  State<Pushpin> createState() => _PushpinState();
}

class _PushpinState extends State<Pushpin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
    _shadowAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(Pushpin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPressed && !oldWidget.isPressed) {
      _pressController.forward();
    } else if (!widget.isPressed && oldWidget.isPressed) {
      _pressController.reverse();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: WallConstants.pushpinSize,
            height: WallConstants.pushpinSize,
            child: CustomPaint(
              painter: _PushpinPainter(
                color: widget.color,
                shadowOpacity: _shadowAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 图钉绘制器 —— CustomPainter 实现
///
/// 逐层绘制图钉的各个视觉元素，模拟真实图钉的立体外观。
/// 所有尺寸均基于 [size] 的比例计算，确保不同尺寸下比例一致。
class _PushpinPainter extends CustomPainter {
  /// 钉帽颜色
  final Color color;

  /// 阴影不透明度倍率（按压时减弱）
  final double shadowOpacity;

  _PushpinPainter({required this.color, this.shadowOpacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // 钉帽半径：占图钉总尺寸的 36%，留出边缘空间
    final headRadius = size.width * 0.36;

    // === 第1层：投影 ===
    // 偏移绘制模糊阴影，模拟图钉在软木板上的投影
    // 按压时阴影减弱，营造"按下"的视觉反馈
    canvas.save();
    canvas.translate(0.8, 1.5);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22 * shadowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawCircle(Offset(cx, cy), headRadius, shadowPaint);
    canvas.restore();

    // === 第2层：钉帽主体 ===
    // 使用径向渐变模拟球面光照：左上亮 → 中间本色 → 右下暗
    // 渐变中心偏左上 (-0.35, -0.35)，模拟光源从左上方照射
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 1.0,
        colors: [
          _lighten(color, 0.3),
          color,
          _darken(color, 0.25),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: headRadius));
    canvas.drawCircle(Offset(cx, cy), headRadius, bodyPaint);

    // === 第3层：钉帽边缘 ===
    // 深色描边勾勒钉帽轮廓，增强立体感和边缘清晰度
    final rimPaint = Paint()
      ..color = _darken(color, 0.35).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(Offset(cx, cy), headRadius, rimPaint);

    // === 第4层：高光 ===
    // 在钉帽左上区域绘制小范围高光，模拟光滑塑料表面的镜面反射
    // 高光中心偏左上，半径为钉帽的 60%，渐变从白色半透明到透明
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.5),
        radius: 0.5,
        colors: [
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(cx - headRadius * 0.25, cy - headRadius * 0.25),
        radius: headRadius * 0.6,
      ));
    canvas.drawCircle(Offset(cx, cy), headRadius * 0.8, highlightPaint);

    // === 第5层：钉尖 ===
    // 钉尖是图钉中心的小金属圆点，使用径向渐变模拟金属质感
    // 从白色高光 → 浅灰 → 深灰，模拟金属的反射特性
    final needleRadius = size.width * 0.06;
    final needlePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.85),
          AppColors.needleLight,
          AppColors.needleMid,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: needleRadius));
    canvas.drawCircle(Offset(cx, cy), needleRadius, needlePaint);

    // === 第6层：钉尖边缘 ===
    // 深灰色细描边，勾勒钉尖轮廓
    final needleRimPaint = Paint()
      ..color = AppColors.needleDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.25;
    canvas.drawCircle(Offset(cx, cy), needleRadius, needleRimPaint);
  }

  /// 颜色变亮工具方法
  ///
  /// 将颜色向白色方向混合 [amount]（0.0~1.0），
  /// 公式：result = original + (255 - original) * amount
  Color _lighten(Color c, double amount) {
    return Color.fromARGB(
      (c.a * 255.0).round().clamp(0, 255),
      ((c.r * 255.0).round() + (255 - (c.r * 255.0).round()) * amount)
          .clamp(0, 255)
          .toInt(),
      ((c.g * 255.0).round() + (255 - (c.g * 255.0).round()) * amount)
          .clamp(0, 255)
          .toInt(),
      ((c.b * 255.0).round() + (255 - (c.b * 255.0).round()) * amount)
          .clamp(0, 255)
          .toInt(),
    );
  }

  /// 颜色变暗工具方法
  ///
  /// 将颜色向黑色方向衰减 [amount]（0.0~1.0），
  /// 公式：result = original * (1 - amount)
  Color _darken(Color c, double amount) {
    return Color.fromARGB(
      (c.a * 255.0).round().clamp(0, 255),
      ((c.r * 255.0).round() * (1 - amount)).clamp(0, 255).toInt(),
      ((c.g * 255.0).round() * (1 - amount)).clamp(0, 255).toInt(),
      ((c.b * 255.0).round() * (1 - amount)).clamp(0, 255).toInt(),
    );
  }

  @override
  bool shouldRepaint(covariant _PushpinPainter oldDelegate) {
    return color != oldDelegate.color ||
        shadowOpacity != oldDelegate.shadowOpacity;
  }
}
