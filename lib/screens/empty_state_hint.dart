import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 空状态提示组件
///
/// 当画布上没有任何卡片和照片时显示，
/// 引导用户了解基本操作方式：
/// - 右下角 + 按钮添加线索
/// - 单击选中 · 双击编辑
/// - 双指缩放 · 双击空白适应
/// - 长按图钉拖拽连线
///
/// 使用仿古纸容器 + 和纸胶带 + 图钉图标的组合，
/// 与整体侦探风格保持一致。
///
/// 包含以下动画效果：
/// - 整体淡入上滑动画
/// - 图钉脉冲动画（吸引注意力）
/// - 提示行交错淡入动画
class EmptyStateHint extends StatefulWidget {
  const EmptyStateHint({super.key});

  @override
  State<EmptyStateHint> createState() => _EmptyStateHintState();
}

class _EmptyStateHintState extends State<EmptyStateHint>
    with TickerProviderStateMixin {
  late final AnimationController _fadeInController;
  late final Animation<double> _fadeInAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();

    // 整体淡入动画
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOutCubic,
    );

    // 图钉脉冲动画
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // 提示行交错动画
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 启动动画序列
    _fadeInController.forward().then((_) {
      _pulseController.repeat(reverse: true);
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _pulseController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_fadeInAnimation),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
              decoration: BoxDecoration(
                color: AppColors.agedPaper.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.sepia.withValues(alpha: 0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(4, 8),
                  ),
                  BoxShadow(
                    color: AppColors.sepia.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  // 脉冲动画的图钉
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.redThread.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.push_pin,
                        size: 32,
                        color: AppColors.redThread.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '点击右下角 +',
                    style: TextStyle(
                      color: AppColors.inkBlack.withValues(alpha: 0.7),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '添加第一条线索',
                    style: TextStyle(
                      color: AppColors.inkBlack.withValues(alpha: 0.45),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.corkBoard.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.sepia.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      children: [
                        _animatedHintRow(0, Icons.add_circle_outline, '右下角 + 添加线索'),
                        const SizedBox(height: 6),
                        _animatedHintRow(1, Icons.touch_app, '单击选中 · 双击编辑'),
                        const SizedBox(height: 6),
                        _animatedHintRow(2, Icons.pinch, '双指缩放 · 双击空白适应'),
                        const SizedBox(height: 6),
                        _animatedHintRow(3, Icons.timeline, '长按图钉拖拽连线'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建带动画的单行提示（图标 + 文字）
  Widget _animatedHintRow(int index, IconData icon, String text) {
    final animation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(
        index * 0.12,
        (index * 0.12 + 0.65).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.warmGray.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: AppColors.warmGray.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
