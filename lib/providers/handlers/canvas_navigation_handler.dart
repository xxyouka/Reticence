/// 画布导航处理器
///
/// 管理画布的平移、缩放和边界约束操作。负责以下核心功能：
/// - 跟踪当前画布缩放比例
/// - 画布边界约束（防止画布被拖出可视区域）
/// - 缩放至适配（将所有卡片纳入视野）
/// - 缩放至指定卡片（居中显示某张卡片）
/// - 矩阵变换的动画过渡（平滑缩放/平移）
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/wall_constants.dart';
import '../../utils/canvas_matrix.dart';

/// 画布导航处理器
///
/// 在应用架构中，该处理器负责所有与画布视口变换相关的逻辑。
/// 它与 [TransformationController] 协同工作，通过 Matrix4 矩阵
/// 控制画布的平移和缩放状态。所有缩放/平移操作都通过动画过渡
/// 实现，确保用户体验流畅。
///
/// 典型调用链：
/// 1. 用户手势触发 → onTransformationUpdate 更新缩放值
/// 2. 手势结束后 → clampCanvasBounds 约束画布位置
/// 3. 用户点击"适配全部" → zoomToFit 计算最佳视口并动画过渡
/// 4. 用户点击某张卡片 → zoomToCard 居中显示该卡片
class CanvasNavigationHandler {
  /// 当前画布的缩放比例，在每次变换更新时同步维护。
  /// 用于其他处理器（如连接线吸附）根据缩放级别调整交互参数。
  double canvasScale = 1.0;

  /// 当前正在执行的缩放动画实例。
  /// 保存引用以便在新动画启动时正确移除旧动画的监听器，
  /// 防止多个动画同时驱动 TransformationController 导致冲突。
  Animation<Matrix4>? _currentZoomAnimation;

  /// 当前动画的帧监听器引用，用于在动画完成或被替换时移除。
  VoidCallback? _currentZoomListener;

  /// 当前动画的状态监听器引用，用于在动画完成时执行清理。
  void Function(AnimationStatus)? _currentZoomStatusListener;

  /// 变换更新回调
  ///
  /// 在 InteractiveViewer 的 onTransformUpdated 中调用，
  /// 从变换矩阵中提取最大轴向缩放值并同步到 [canvasScale]。
  /// 使用 canvasMatrixScale() 只读取 x/y 轴缩放，避免 z 轴 1.0
  /// 导致缩小到 1 以下时被误判为 1。
  void onTransformationUpdate(Matrix4 matrix) {
    canvasScale = canvasMatrixScale(matrix);
  }

  /// 画布边界约束
  ///
  /// 当用户拖动画布超出允许范围时，将画布位置约束回合法区域。
  /// 约束逻辑基于画布虚拟尺寸和屏幕尺寸计算平移量的上下限：
  ///
  /// - [minTx] = 屏幕宽度 - 画布宽度 × 缩放 - 边距
  ///   表示画布左边缘最多能向左偏移的距离（画布右边缘不超出屏幕右侧太多）
  /// - [maxTx] = 边距
  ///   表示画布左边缘最多能向右偏移的距离（画布左边缘不超出屏幕左侧太多）
  ///
  /// Y 轴同理。当平移量超出 [minTx, maxTx] 范围时，将其钳制到边界值，
  /// 并通过动画平滑过渡到约束后的位置。
  ///
  /// [margin] 设为 200.0 是为了在画布边缘和屏幕边缘之间保留一定的
  /// 可视缓冲区，避免画布紧贴屏幕边缘导致视觉上不舒适，
  /// 同时允许用户看到画布边界附近的内容。
  void clampCanvasBounds(
    TransformationController transformController,
    AnimationController zoomController,
    Size screenSize,
  ) {
    final matrix = transformController.value;
    final scale = canvasMatrixScale(matrix);
    final tx = matrix.getTranslation();
    double newTx = tx.x;
    double newTy = tx.y;

    // 边距：画布边缘允许超出屏幕的最大像素距离。
    // 200px 约占手机屏幕宽度的 1/3，在保证画布不会
    // 完全滑出视野的同时，给予用户足够的拖动自由度。
    const margin = 200.0;

    // 计算平移量的约束范围
    // minTx/minTy：画布在该方向上允许的最小偏移（向左/向上拖动的极限）
    // maxTx/maxTy：画布在该方向上允许的最大偏移（向右/向下拖动的极限）
    final minTx = screenSize.width - WallConstants.canvasWidth * scale - margin;
    const maxTx = margin;
    final minTy =
        screenSize.height - WallConstants.canvasHeight * scale - margin;
    const maxTy = margin;

    // 逐轴检查并钳制平移量
    bool needsClamp = false;
    if (newTx < minTx) {
      newTx = minTx;
      needsClamp = true;
    }
    if (newTx > maxTx) {
      newTx = maxTx;
      needsClamp = true;
    }
    if (newTy < minTy) {
      newTy = minTy;
      needsClamp = true;
    }
    if (newTy > maxTy) {
      newTy = maxTy;
      needsClamp = true;
    }

    if (needsClamp) {
      // 构建约束后的目标矩阵
      // 注意：Matrix4 的 scale + translate 顺序很重要，
      // translate 的参数需要除以 scale，因为 scale 是先应用的，
      // 后续的平移量会被缩放因子放大，所以需要预除以 scale 来补偿。
      final target = canvasMatrixFromScaleAndTranslation(
        scale: scale,
        tx: newTx,
        ty: newTy,
      );
      _animateToMatrix(transformController, zoomController, target);
    }
  }

  /// 缩放至适配所有卡片
  ///
  /// 计算所有卡片的最小包围矩形（AABB），然后确定一个缩放比例
  /// 和平移量，使得该包围矩形在屏幕上居中显示且完全可见。
  ///
  /// 算法步骤：
  /// 1. 遍历所有卡片的边界框，计算全局最小/最大坐标
  /// 2. 在内容区域四周添加 [WallConstants.fitPadding] 的内边距，
  ///    确保卡片不会紧贴屏幕边缘
  /// 3. 计算适配缩放比例 = min(屏幕宽/内容宽, 屏幕高/内容高)，
  ///    取较小值保证两个方向都能完整显示
  /// 4. 将缩放比例钳制到 [minScale, maxScale] 范围内，
  ///    防止过度放大或缩小
  /// 5. 计算居中偏移量，使内容中心对齐屏幕中心
  void zoomToFit(
    TransformationController transformController,
    AnimationController zoomController,
    List<({double x, double y, double w, double h})> bounds,
    Size screenSize,
  ) {
    if (bounds.isEmpty) return;

    // 计算所有卡片的全局包围盒
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final b in bounds) {
      minX = min(minX, b.x);
      minY = min(minY, b.y);
      maxX = max(maxX, b.x + b.w);
      maxY = max(maxY, b.y + b.h);
    }

    // 内容尺寸 = 包围盒尺寸 + 两侧内边距
    // fitPadding 确保卡片群与屏幕边缘之间有呼吸空间
    final contentW = maxX - minX + WallConstants.fitPadding * 2;
    final contentH = maxY - minY + WallConstants.fitPadding * 2;

    // 缩放比例：取宽高比中较小的值，确保内容在两个维度都完整可见
    // clamp 到合法范围，避免极端缩放
    final scale = min(screenSize.width / contentW, screenSize.height / contentH)
        .clamp(WallConstants.minScale, WallConstants.maxScale);

    // 计算居中平移量
    // 使内容中心点映射到屏幕中心：
    // 屏幕中心 = 内容中心 × scale + 平移量
    // => 平移量 = 屏幕中心 - 内容中心 × scale
    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;
    final tx = screenSize.width / 2 - centerX * scale;
    final ty = screenSize.height / 2 - centerY * scale;

    final matrix = canvasMatrixFromScaleAndTranslation(
      scale: scale,
      tx: tx,
      ty: ty,
    );

    canvasScale = scale;
    _animateToMatrix(transformController, zoomController, matrix);
  }

  /// 缩放至指定卡片
  ///
  /// 将视口平移和缩放，使目标卡片居中显示在屏幕上。
  /// 保持当前缩放比例不变（除非超出合法范围），
  /// 仅调整平移量使卡片中心对齐屏幕中心。
  void zoomToCard(
    TransformationController transformController,
    AnimationController zoomController,
    double cardX,
    double cardY,
    Size screenSize, {
    double cardWidth = WallConstants.cardWidth,
    double cardHeight = WallConstants.cardHeight,
  }) {
    // 保持当前缩放比例，但确保在合法范围内
    final currentScale = canvasMatrixScale(transformController.value);
    final scale =
        currentScale.clamp(WallConstants.minScale, WallConstants.maxScale);

    // 计算使卡片中心对齐屏幕中心的平移量
    final tx = screenSize.width / 2 - (cardX + cardWidth / 2) * scale;
    final ty = screenSize.height / 2 - (cardY + cardHeight / 2) * scale;

    final matrix = canvasMatrixFromScaleAndTranslation(
      scale: scale,
      tx: tx,
      ty: ty,
    );

    canvasScale = scale;
    _animateToMatrix(transformController, zoomController, matrix);
  }

  /// 矩阵变换动画过渡
  ///
  /// 将 [TransformationController] 的当前值平滑过渡到目标矩阵 [target]。
  /// 使用 Matrix4Tween 在两个矩阵之间插值，配合 easeOutCubic 曲线
  /// 实现先快后慢的减速效果，让动画结尾更自然。
  ///
  /// 关键设计：
  /// - 每次启动新动画前，先移除旧动画的监听器，避免多个动画
  ///   同时驱动同一个 TransformationController 产生冲突
  /// - 动画完成（completed 或 dismissed）后自动移除监听器并清空引用，
  ///   防止内存泄漏
  /// - 使用 Curves.easeOutCubic 而非 easeInOut，因为缩放/平移动画
  ///   通常由用户操作触发，用户期望立即看到响应（快速启动），
  ///   然后平滑减速到目标位置
  void _animateToMatrix(
    TransformationController transformController,
    AnimationController zoomController,
    Matrix4 target,
  ) {
    // 移除旧动画的监听器，防止旧动画继续驱动变换控制器
    if (_currentZoomAnimation != null && _currentZoomListener != null) {
      _currentZoomAnimation!.removeListener(_currentZoomListener!);
    }
    if (_currentZoomAnimation != null && _currentZoomStatusListener != null) {
      _currentZoomAnimation!.removeStatusListener(_currentZoomStatusListener!);
    }

    // 停止当前正在进行的动画控制器
    zoomController.stop();

    // 创建从当前矩阵到目标矩阵的补间动画
    final animation = Matrix4Tween(
      begin: transformController.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: zoomController..forward(from: 0),
      curve: Curves.easeOutCubic,
    ));

    // 帧监听器：每帧将动画插值结果写入变换控制器
    void listener() {
      transformController.value = animation.value;
    }

    // 状态监听器：动画结束时清理所有监听器和引用
    void statusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animation.removeListener(listener);
        animation.removeStatusListener(statusListener);
        _currentZoomAnimation = null;
        _currentZoomListener = null;
        _currentZoomStatusListener = null;
      }
    }

    // 保存引用以便后续清理
    _currentZoomAnimation = animation;
    _currentZoomListener = listener;
    _currentZoomStatusListener = statusListener;

    animation.addListener(listener);
    animation.addStatusListener(statusListener);
  }
}
