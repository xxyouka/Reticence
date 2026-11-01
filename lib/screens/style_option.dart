import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 照片风格选项卡片
///
/// 在风格选择器中展示单个风格选项，包含预览色块、标签和描述。
/// 按下时有缩放反馈动画，模拟实体卡片的按压感。
/// 包含入场淡入动画。
class StyleOption extends StatefulWidget {
  final String label;
  final String description;
  final Color borderColor;
  final Color bgColor;
  final VoidCallback onTap;

  const StyleOption({
    super.key,
    required this.label,
    required this.description,
    required this.borderColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<StyleOption> createState() => _StyleOptionState();
}

class _StyleOptionState extends State<StyleOption>
    with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _pressController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _pressController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_entranceAnimation),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.vintageCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.sepia.withValues(alpha: 0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: AppColors.sepia.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 拍立得预览缩影
                  Container(
                    width: 72,
                    height: 88,
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12),
                        width: 0.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(2, 3),
                          blurRadius: 6,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.warmGray.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Icon(
                          Icons.image,
                          size: 24,
                          color: AppColors.warmGray.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkBlack.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.inkBlack.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
