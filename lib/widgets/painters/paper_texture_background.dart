/// 纸张纹理背景组件
///
/// 侦探线索墙应用的视觉核心组件，负责渲染线索墙的背景纹理效果。
/// 通过多层叠加的绘制算法，模拟真实软木板和旧纸张的质感，
/// 为整个应用奠定侦探推理的沉浸式视觉基调。
///
/// 纹理系统架构：
/// 1. 基础层：纯色背景（baseColor）
/// 2. 贴图层：可选的 PNG 纹理贴图（paper 模式），贴图加载失败时回退到程序化绘制
/// 3. 咖啡渍层：[_CoffeeStainOverlay]——模拟纸张上不小心洒落的咖啡渍
/// 4. 折痕层：[_FoldLineOverlay]——模拟纸张对折后留下的折痕
/// 5. 边框层：[_FramePainter]——可选的画框装饰（经典/现代两种风格）
/// 6. 边框纹理层：[_FrameTextureOverlay]——经典画框的木纹叠加
///
/// 两种纹理模式：
/// - [TextureMode.cork]：软木板模式，用于线索墙主背景
/// - [TextureMode.paper]：纸张模式，用于人物卡片背景
///
/// 渲染策略：
/// - 优先使用预制的 PNG 纹理贴图（性能更优）
/// - 贴图加载失败时自动回退到 [_FallbackTexturePainter] 的程序化绘制
/// - 程序化绘制使用固定种子（42）的伪随机数生成器，确保每次渲染结果一致
/// - 所有 CustomPainter 的 shouldRepaint 均做了精确的条件判断，避免不必要的重绘
library;

import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 纹理模式枚举
///
/// 定义两种背景纹理风格，对应不同的侦探工作场景：
/// - [cork]：软木板纹理，模拟侦探办公室中用于钉卡片的软木公告板
/// - [paper]：纸张纹理，模拟人物便签卡的旧纸张质感
enum TextureMode { cork, paper }

/// 画框风格枚举
///
/// 定义两种画框装饰风格，用于增强线索墙的视觉层次：
/// - [none]：无画框，纯纹理背景
/// - [classic]：经典画框，模拟实木相框，带斜面倒角和角落装饰
/// - [modern]：现代画框，简约窄边框，内边缘带微小圆角
enum FrameStyle { none, classic, modern }

/// 纸张纹理背景组件
///
/// 通过多层 CustomPaint 叠加渲染逼真的纹理效果。
/// 支持咖啡渍、折痕、老化效果和画框装饰等可选叠加层。
///
/// 使用方式：
/// ```dart
/// PaperTextureBackground(
///   baseColor: AppColors.corkBoard,
///   mode: TextureMode.cork,
///   child: // 线索墙内容
/// )
/// ```
///
/// 渲染层次（从底到顶）：
/// 1. baseColor 纯色背景
/// 2. PNG 纹理贴图 或 程序化回退纹理
/// 3. 咖啡渍叠加（仅 paper 模式 + showCoffeeStain）
/// 4. 折痕叠加（仅 paper 模式 + showFoldLine）
/// 5. 画框装饰（仅 frameStyle != none）
/// 6. 画框纹理叠加（仅 classic 画框）
/// 7. child 内容层
class PaperTextureBackground extends StatelessWidget {
  /// 基础背景色
  final Color baseColor;

  /// 纹理整体透明度
  final double opacity;

  /// 子组件，显示在纹理层之上
  final Widget? child;

  /// 是否显示老化效果（纸张泛黄变色）
  final bool showAging;

  /// 是否显示咖啡渍效果
  final bool showCoffeeStain;

  /// 是否显示折痕效果
  final bool showFoldLine;

  /// 纹理模式：软木板 或 纸张
  final TextureMode mode;

  /// 画框风格
  final FrameStyle frameStyle;

  /// 画框宽度（像素）
  final double frameWidth;

  const PaperTextureBackground({
    super.key,
    required this.baseColor,
    this.opacity = 1.0,
    this.child,
    this.showAging = false,
    this.showCoffeeStain = false,
    this.showFoldLine = false,
    this.mode = TextureMode.paper,
    this.frameStyle = FrameStyle.none,
    this.frameWidth = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      // 有子组件时使用 expand 模式，确保纹理铺满整个可用空间
      return Stack(
        fit: StackFit.expand,
        children: [
          // 纹理绘制层
          Positioned.fill(
            child: _TexturePainter(
              baseColor: baseColor,
              opacity: opacity,
              showAging: showAging,
              showCoffeeStain: showCoffeeStain,
              showFoldLine: showFoldLine,
              mode: mode,
              frameStyle: frameStyle,
              frameWidth: frameWidth,
            ),
          ),
          // 画框装饰层
          if (frameStyle != FrameStyle.none) _buildFrameDecoration(context),
          // 子组件层
          child!,
        ],
      );
    }
    // 无子组件时使用简单 Stack
    return Stack(
      children: [
        _TexturePainter(
          baseColor: baseColor,
          opacity: opacity,
          showAging: showAging,
          showCoffeeStain: showCoffeeStain,
          showFoldLine: showFoldLine,
          mode: mode,
          frameStyle: frameStyle,
          frameWidth: frameWidth,
        ),
        if (frameStyle != FrameStyle.none) _buildFrameDecoration(context),
      ],
    );
  }

  /// 构建画框装饰层
  ///
  /// 使用 IgnorePointer 包裹，确保画框不会拦截触摸事件。
  /// 画框由两部分组成：
  /// 1. [_FramePainter]：绘制画框的几何形状和渐变
  /// 2. [_FrameTextureOverlay]（仅 classic 模式）：叠加木纹纹理
  Widget _buildFrameDecoration(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // 画框几何绘制
              CustomPaint(
                size: constraints.biggest,
                painter: _FramePainter(
                  style: frameStyle,
                  width: frameWidth,
                ),
              ),
              // 经典画框的木纹纹理叠加
              if (frameStyle == FrameStyle.classic)
                _FrameTextureOverlay(
                  width: frameWidth,
                  size: constraints.biggest,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 纹理绘制器
///
/// 负责渲染基础纹理层，包括纯色背景、PNG 纹理贴图和程序化回退纹理。
/// 当 PNG 贴图可用时优先使用贴图（性能更优、效果更逼真），
/// 贴图加载失败时自动回退到 [_FallbackTexturePainter] 的程序化绘制。
///
/// 贴图选择逻辑：
/// - cork 模式：始终使用程序化绘制（无预制贴图）
/// - paper 模式 + showAging：使用程序化绘制（老化效果需要动态生成）
/// - paper 模式 + 无老化：使用 PNG 贴图 'assets/textures/texture_paper.png'
class _TexturePainter extends StatelessWidget {
  final Color baseColor;
  final double opacity;
  final bool showAging;
  final bool showCoffeeStain;
  final bool showFoldLine;
  final TextureMode mode;
  final FrameStyle frameStyle;
  final double frameWidth;

  const _TexturePainter({
    required this.baseColor,
    required this.opacity,
    required this.showAging,
    required this.showCoffeeStain,
    required this.showFoldLine,
    required this.mode,
    this.frameStyle = FrameStyle.none,
    this.frameWidth = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    // 根据模式和老化设置决定是否使用 PNG 贴图
    final assetPath = mode == TextureMode.cork
        ? null // 软木板模式始终使用程序化绘制
        : (showAging
            ? null // 老化效果需要动态生成，无法使用静态贴图
            : 'assets/textures/texture_paper.png'); // 标准纸张模式使用预制贴图

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        // 防止在尺寸未确定时绘制（如布局阶段）
        if (size.width <= 0 || size.height <= 0) {
          return const SizedBox.shrink();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // 第一层：纯色背景
            Container(color: baseColor),
            // 第二层：PNG 纹理贴图（带回退机制）
            if (assetPath != null)
              Image.asset(
                assetPath,
                // 不缩放，保持原始分辨率
                fit: BoxFit.none,
                // 平铺重复，覆盖整个区域
                repeat: ImageRepeat.repeat,
                // 应用整体透明度
                opacity: AlwaysStoppedAnimation(opacity),
                // 贴图加载失败时回退到程序化绘制
                errorBuilder: (context, error, stackTrace) {
                  return CustomPaint(
                    size: size,
                    painter: _FallbackTexturePainter(
                      baseColor: baseColor,
                      showAging: showAging,
                      showCoffeeStain: showCoffeeStain,
                      showFoldLine: showFoldLine,
                      mode: mode,
                    ),
                  );
                },
              ),
            // 第三层：咖啡渍叠加（仅纸张模式）
            if (showCoffeeStain && mode == TextureMode.paper)
              CustomPaint(
                size: size,
                painter: _CoffeeStainOverlay(),
              ),
            // 第四层：折痕叠加（仅纸张模式）
            if (showFoldLine && mode == TextureMode.paper)
              CustomPaint(
                size: size,
                painter: _FoldLineOverlay(),
              ),
          ],
        );
      },
    );
  }
}

/// 程序化回退纹理绘制器
///
/// 当 PNG 纹理贴图不可用时，使用 Canvas API 程序化生成纹理效果。
/// 虽然性能不如贴图，但无需外部资源依赖，且支持动态效果（如老化）。
///
/// 算法设计原则：
/// - 使用固定种子（42）的伪随机数生成器，确保同一帧内多次绘制结果一致
/// - 纹理密度根据画布面积动态计算，适应不同屏幕尺寸
/// - 所有透明度值都经过精心调整，确保纹理效果自然不突兀
/// - 分层绘制：先绘制大面积效果，再叠加细节纹理
class _FallbackTexturePainter extends CustomPainter {
  final Color baseColor;
  final bool showAging;
  final bool showCoffeeStain;
  final bool showFoldLine;
  final TextureMode mode;

  _FallbackTexturePainter({
    required this.baseColor,
    required this.showAging,
    required this.showCoffeeStain,
    required this.showFoldLine,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 绘制基础色背景
    final basePaint = Paint()..color = baseColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // 根据纹理模式选择绘制算法
    if (mode == TextureMode.cork) {
      _drawCorkFallback(canvas, size);
    } else {
      _drawPaperFallback(canvas, size);
    }
  }

  /// 程序化绘制软木板纹理
  ///
  /// 软木板纹理由四个层次叠加组成：
  /// 1. 颗粒层：大量随机分布的小圆点，模拟软木的颗粒质感
  /// 2. 孔洞层：较大的深色圆点，模拟软木板表面的天然孔洞
  /// 3. 条纹层：水平方向的细微线条，模拟软木的纤维纹理
  /// 4. 暗角层：径向渐变，模拟边缘变暗的视觉效果
  void _drawCorkFallback(Canvas canvas, Size size) {
    // 使用固定种子的随机数生成器，确保渲染结果可复现
    final rng = Random(42);

    // ---- 第一层：颗粒纹理 ----
    // 密度：每 40 平方像素一个颗粒点
    final grainCount = (size.width * size.height / 40).ceil();
    for (int i = 0; i < grainCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      // 颗粒大小在 0.4~2.2 像素之间
      final dotSize = rng.nextDouble() * 1.8 + 0.4;
      // 约 45% 的颗粒使用浅色，55% 使用深色，模拟软木的自然色差
      final isLight = rng.nextDouble() > 0.55;
      // 极低透明度（0.02~0.08），大量叠加后形成自然纹理
      final alpha = rng.nextDouble() * 0.06 + 0.02;
      final color = isLight
          ? AppColors.corkBoardLight.withValues(alpha: alpha)
          : AppColors.corkBoardDark.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), dotSize / 2, Paint()..color = color);
    }

    // ---- 第二层：孔洞纹理 ----
    // 密度：每 800 平方像素一个孔洞（比颗粒稀疏得多）
    final holeCount = (size.width * size.height / 800).ceil();
    for (int i = 0; i < holeCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      // 孔洞半径在 1.0~3.5 像素之间
      final radius = rng.nextDouble() * 2.5 + 1.0;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        // 深色半透明，模拟孔洞的阴影效果
        Paint()
          ..color = AppColors.corkBoardDark
              .withValues(alpha: 0.08 + rng.nextDouble() * 0.06),
      );
    }

    // ---- 第三层：纤维条纹 ----
    // 密度：每 18 像素高度一条水平条纹
    final streakCount = (size.height / 18).ceil();
    for (int i = 0; i < streakCount; i++) {
      final y = rng.nextDouble() * size.height;
      final alpha = rng.nextDouble() * 0.04 + 0.01;
      final strokeWidth = rng.nextDouble() * 2 + 0.5;
      // 条纹略有弯曲（Y 方向偏移 ±4 像素），模拟天然纤维的不规则走向
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (rng.nextDouble() - 0.5) * 8),
        Paint()
          ..color = AppColors.corkBoardDark.withValues(alpha: alpha)
          ..strokeWidth = strokeWidth,
      );
    }

    // ---- 第四层：暗角效果 ----
    // 径向渐变从中心透明到边缘深色，模拟自然光照的暗角效果
    final vignetteRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent, // 中心完全透明
          Colors.transparent, // 60% 半径处仍透明
          AppColors.corkFrame.withValues(alpha: 0.15), // 85% 半径处开始变暗
          AppColors.corkFrame.withValues(alpha: 0.35), // 边缘最暗
        ],
        stops: const [0.0, 0.6, 0.85, 1.0],
      ).createShader(vignetteRect);
    canvas.drawRect(vignetteRect, vignettePaint);
  }

  /// 程序化绘制纸张纹理
  ///
  /// 纸张纹理由三个层次叠加组成：
  /// 1. 老化层：对角线渐变，模拟纸张随时间泛黄变色的效果
  /// 2. 颗粒层：大量随机分布的微小圆点，模拟纸张表面的粗糙质感
  /// 3. 纤维层：随机方向的短线段，模拟纸张中的植物纤维
  void _drawPaperFallback(Canvas canvas, Size size) {
    final rng = Random(42);

    // ---- 第一层：老化效果 ----
    // 从左上到右下的对角线渐变，模拟纸张不均匀的老化变色
    if (showAging) {
      final agePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.coffeeStain.withValues(alpha: 0.08), // 左上角轻微泛黄
            Colors.transparent, // 中间保持原色
            AppColors.coffeeStain.withValues(alpha: 0.05), // 右下角轻微泛黄
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), agePaint);
    }

    // ---- 第二层：颗粒纹理 ----
    // 密度：每 60 平方像素一个颗粒点（比软木板稀疏）
    final grainCount = (size.width * size.height / 60).ceil();
    for (int i = 0; i < grainCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      // 颗粒更小（0.2~1.0 像素），纸张比软木板更细腻
      final dotSize = rng.nextDouble() * 0.8 + 0.2;
      // 50% 概率为深色或浅色，模拟纸张表面的明暗变化
      final isDark = rng.nextDouble() > 0.5;
      // 极低透明度，大量叠加形成微妙的纹理
      final alpha = rng.nextDouble() * 0.025 + 0.008;
      final color = isDark
          ? Colors.black.withValues(alpha: alpha)
          : Colors.white.withValues(alpha: alpha * 0.6); // 浅色颗粒更淡
      canvas.drawCircle(Offset(x, y), dotSize / 2, Paint()..color = color);
    }

    // ---- 第三层：纤维纹理 ----
    // 密度：每 2000 平方像素一根纤维（非常稀疏）
    final fiberCount = (size.width * size.height / 2000).ceil();
    for (int i = 0; i < fiberCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      // 纤维长度 2~8 像素
      final length = rng.nextDouble() * 6 + 2;
      // 随机角度，模拟纸张中纤维的无序排列
      final angle = rng.nextDouble() * pi;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + cos(angle) * length, y + sin(angle) * length),
        Paint()
          ..color = AppColors.sepia.withValues(alpha: 0.03) // 极淡的深棕色
          ..strokeWidth = 0.3, // 极细的线宽
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FallbackTexturePainter oldDelegate) {
    // 仅当关键参数变化时才重绘，避免不必要的性能开销
    return baseColor != oldDelegate.baseColor ||
        showAging != oldDelegate.showAging ||
        showCoffeeStain != oldDelegate.showCoffeeStain ||
        showFoldLine != oldDelegate.showFoldLine ||
        mode != oldDelegate.mode;
  }
}

/// 咖啡渍叠加层
///
/// 在纸张纹理上绘制逼真的咖啡渍效果，增强旧纸张的年代感。
/// 咖啡渍由三部分组成：
/// 1. 主体：径向渐变的圆形区域，模拟咖啡液体的扩散
/// 2. 外环：较深的描边圆环，模拟咖啡渍边缘的浓缩沉积
/// 3. 内环：较淡的描边圆环，模拟咖啡渍内部的二次沉积
///
/// 位置算法：咖啡渍出现在画布右下区域（55%~90% 宽度 × 45%~80% 高度），
/// 模拟右手持杯时自然洒落的位置。
class _CoffeeStainOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42);
    // 咖啡渍位置偏右下方，模拟右手持杯洒落的自然位置
    final stainX = size.width * (0.55 + rng.nextDouble() * 0.35);
    final stainY = size.height * (0.45 + rng.nextDouble() * 0.35);
    // 咖啡渍半径为画布短边的 18%
    final stainRadius = min(size.width, size.height) * 0.18;

    // 主体：多段径向渐变，模拟咖啡液体的不均匀扩散
    final stainPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [
          AppColors.coffeeStain.withValues(alpha: 0.0), // 中心透明
          AppColors.coffeeStain.withValues(alpha: 0.03), // 轻微着色
          AppColors.coffeeStain.withValues(alpha: 0.06), // 最深区域
          AppColors.coffeeStain.withValues(alpha: 0.04), // 开始消退
          AppColors.coffeeStain.withValues(alpha: 0.0), // 边缘透明
        ],
        stops: const [0.0, 0.25, 0.45, 0.65, 1.0],
      ).createShader(
          Rect.fromCircle(center: Offset(stainX, stainY), radius: stainRadius));
    canvas.drawCircle(Offset(stainX, stainY), stainRadius, stainPaint);

    // 外环：模拟咖啡渍边缘的浓缩沉积环
    final ringPaint = Paint()
      ..color = AppColors.coffeeStain.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(stainX, stainY), stainRadius * 0.82, ringPaint);

    // 内环：模拟咖啡渍内部的二次沉积环
    final innerRingPaint = Paint()
      ..color = AppColors.coffeeStain.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(
        Offset(stainX, stainY), stainRadius * 0.6, innerRingPaint);
  }

  @override
  bool shouldRepaint(covariant _CoffeeStainOverlay oldDelegate) => false;
}

/// 折痕叠加层
///
/// 在纸张纹理上绘制垂直折痕效果，模拟纸张对折后留下的痕迹。
/// 折痕由两部分组成：
/// 1. 折线：垂直居中的深棕色细线
/// 2. 折影：折线两侧的明暗渐变，模拟折叠处的光影效果
///
/// 光影算法：折线左侧略暗（阴影）、右侧略亮（高光），
/// 这模拟了光源从左上方照射时折叠处产生的自然明暗变化。
class _FoldLineOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 折线：垂直居中的深棕色细线
    final foldPaint = Paint()
      ..color = AppColors.sepia.withValues(alpha: 0.1)
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      foldPaint,
    );

    // 折影：折线两侧 10px 宽度的明暗渐变
    // 从左到右：透明 → 微暗 → 透明 → 微亮 → 透明
    // 模拟折叠处左侧阴影、右侧高光的光影效果
    final foldShadow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent, // 远离折线处透明
          Colors.black.withValues(alpha: 0.03), // 折线左侧微暗（阴影）
          Colors.transparent, // 折线处透明
          Colors.white.withValues(alpha: 0.03), // 折线右侧微亮（高光）
          Colors.transparent, // 远离折线处透明
        ],
        stops: const [0.0, 0.47, 0.5, 0.53, 1.0],
      ).createShader(Rect.fromLTWH(size.width / 2 - 10, 0, 20, size.height));
    canvas.drawRect(
        Rect.fromLTWH(size.width / 2 - 10, 0, 20, size.height), foldShadow);
  }

  @override
  bool shouldRepaint(covariant _FoldLineOverlay oldDelegate) => false;
}

/// 画框绘制器
///
/// 根据画框风格绘制不同的边框装饰效果。
/// 支持两种风格：
/// - [FrameStyle.classic]：经典实木画框，包含木纹渐变、内外斜面倒角和角落装饰
/// - [FrameStyle.modern]：现代简约画框，纯色窄边框 + 内边缘微小圆角
class _FramePainter extends CustomPainter {
  final FrameStyle style;
  final double width;

  _FramePainter({required this.style, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    if (style == FrameStyle.classic) {
      _drawClassicFrame(canvas, size);
    } else if (style == FrameStyle.modern) {
      _drawModernFrame(canvas, size);
    }
  }

  /// 绘制经典实木画框
  ///
  /// 经典画框由四个视觉层次组成：
  /// 1. 主体：木纹渐变的矩形环（外矩形 - 内矩形，使用 evenOdd 填充）
  /// 2. 内倒角：内侧边缘的暗色渐变，模拟光线在斜面上的阴影
  /// 3. 外倒角：外侧边缘的亮色渐变，模拟光线在斜面上的高光
  /// 4. 角落装饰：四角的圆形装饰点，模拟实木画框的角钉
  ///
  /// evenOdd 填充规则：外矩形和内矩形之间的区域被填充，
  /// 内矩形内部不被填充，形成中空的画框效果。
  void _drawClassicFrame(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final outerRect = rect;
    final innerRect = rect.deflate(width);

    // ---- 第一层：画框主体 ----
    // 对角线渐变模拟木纹的明暗变化
    final woodFramePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.corkFrame.withValues(alpha: 0.95), // 浅木色
          AppColors.corkBoardDark.withValues(alpha: 0.85), // 深木色
          AppColors.corkFrame.withValues(alpha: 0.9), // 浅木色
          AppColors.corkBoardDark.withValues(alpha: 0.88), // 深木色
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(outerRect);

    // 使用 evenOdd 填充规则创建中空的画框路径
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(outerRect, Radius.zero))
      ..addRRect(RRect.fromRectAndRadius(innerRect, Radius.zero))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, woodFramePaint);

    // ---- 第二层：内倒角 ----
    // 内侧边缘 1.5px 宽的暗色渐变，模拟斜面的阴影
    final innerBevelPath = Path()
      ..addRRect(RRect.fromRectAndRadius(innerRect.inflate(1.5), Radius.zero))
      ..addRRect(RRect.fromRectAndRadius(innerRect, Radius.zero))
      ..fillType = PathFillType.evenOdd;

    final innerBevelPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withValues(alpha: 0.25), // 左上角暗
          Colors.transparent, // 右下角透明
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(innerRect.inflate(2));

    canvas.drawPath(innerBevelPath, innerBevelPaint);

    // ---- 第三层：外倒角 ----
    // 外侧边缘 2.5px 宽的亮色渐变，模拟斜面的高光
    final outerBevelPath = Path()
      ..addRRect(RRect.fromRectAndRadius(outerRect, Radius.zero))
      ..addRRect(RRect.fromRectAndRadius(outerRect.deflate(2.5), Radius.zero))
      ..fillType = PathFillType.evenOdd;

    final outerBevelPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.15), // 左上角亮
          Colors.transparent, // 右下角透明
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(outerRect);

    canvas.drawPath(outerBevelPath, outerBevelPaint);

    // ---- 第四层：角落装饰 ----
    // 四角的圆形装饰点，模拟实木画框的金属角钉
    final cornerRadius = width * 0.15;
    final cornerPaint = Paint()
      ..color = AppColors.corkBoardDark.withValues(alpha: 0.4);

    final corners = [
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, cornerRadius, cornerPaint);
    }
  }

  /// 绘制现代简约画框
  ///
  /// 现代画框仅包含一个纯色窄边框（宽度为经典画框的 60%），
  /// 内边缘带有 2px 圆角，营造简约精致的视觉效果。
  void _drawModernFrame(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final outerRect = rect;
    // 现代画框宽度为经典画框的 60%，更加纤细
    final innerRect = rect.deflate(width * 0.6);

    final framePaint = Paint()
      ..color = AppColors.corkFrame.withValues(alpha: 0.9);

    // evenOdd 填充创建中空边框，内边缘带 2px 圆角
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(outerRect, Radius.zero))
      ..addRRect(RRect.fromRectAndRadius(innerRect, const Radius.circular(2)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, framePaint);
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) {
    return style != oldDelegate.style || width != oldDelegate.width;
  }
}

/// 画框纹理叠加层
///
/// 在经典画框上叠加半透明的旧纸色纹理，增强木框的质感。
/// 使用 [_FrameClipper] 裁剪，确保纹理仅出现在画框区域内。
class _FrameTextureOverlay extends StatelessWidget {
  final double width;
  final Size size;

  const _FrameTextureOverlay({required this.width, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      // 使用画框形状裁剪器，确保纹理仅覆盖画框区域
      clipper: _FrameClipper(width: width),
      child: Container(
        // 半透明旧纸色，为画框添加微妙的纹理层次
        color: AppColors.agedPaper.withValues(alpha: 0.6),
        width: size.width,
        height: size.height,
      ),
    );
  }
}

/// 画框形状裁剪器
///
/// 生成与画框形状匹配的裁剪路径（外矩形 - 内矩形），
/// 用于 [_FrameTextureOverlay] 的 ClipPath 裁剪。
/// 使用 evenOdd 填充规则创建中空的矩形环路径。
class _FrameClipper extends CustomClipper<Path> {
  final double width;

  const _FrameClipper({required this.width});

  @override
  Path getClip(Size size) {
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final innerRect = outerRect.deflate(width);
    return Path()
      ..addRRect(RRect.fromRectAndRadius(outerRect, Radius.zero))
      ..addRRect(RRect.fromRectAndRadius(innerRect, Radius.zero))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(covariant _FrameClipper oldClipper) {
    return width != oldClipper.width;
  }
}
