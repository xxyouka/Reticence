/// 通用按压缩放按钮
///
/// 为所有可点击组件提供统一的按下缩放反馈动画。
/// 按下时缩放到 [scaleEnd]，释放时恢复，模拟物理按钮手感。
library;

import 'package:flutter/material.dart';

/// 按压缩放包装器
///
/// 将任意子组件包装为带有按压缩放动画的可点击组件。
/// 通过 [builder] 回调暴露 `isPressed` 状态，支持按下态样式变化。
///
/// 使用方式：
/// ```dart
/// PressScaleButton(
///   onTap: () => print('tapped'),
///   builder: (context, isPressed, child) => Container(
///     decoration: BoxDecoration(
///       boxShadow: isPressed ? deepShadow : lightShadow,
///     ),
///     child: child,
///   ),
///   child: Icon(Icons.add),
/// )
/// ```
class PressScaleButton extends StatefulWidget {
  final VoidCallback? onTap;
  final double scaleEnd;
  final Duration duration;
  final Widget? child;
  final Widget Function(BuildContext context, bool isPressed, Widget? child)?
      builder;

  const PressScaleButton({
    super.key,
    this.onTap,
    this.scaleEnd = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.child,
    this.builder,
  });

  @override
  State<PressScaleButton> createState() => _PressScaleButtonState();
}

class _PressScaleButtonState extends State<PressScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = _buildScaleAnimation();
  }

  @override
  void didUpdateWidget(PressScaleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scaleEnd != widget.scaleEnd) {
      _scaleAnimation = _buildScaleAnimation();
    }
  }

  Animation<double> _buildScaleAnimation() {
    return Tween<double>(begin: 1.0, end: widget.scaleEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? _handleTapUp : null,
      onTapCancel: widget.onTap != null ? _handleTapCancel : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.builder != null
                ? widget.builder!(context, _isPressed, widget.child)
                : child,
          );
        },
        child: widget.builder == null ? widget.child : null,
      ),
    );
  }
}
