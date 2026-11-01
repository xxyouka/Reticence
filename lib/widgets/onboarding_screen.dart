
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final bool autoComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    this.autoComplete = true,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _fadeInController;
  late final Animation<double> _fadeInAnimation;
  late final AnimationController _textFadeController;
  late final Animation<double> _textFadeAnimation;
  late final AnimationController _breatheController;
  late final Animation<double> _breatheScale;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    if (widget.autoComplete) {
      _progressController.addStatusListener(_handleProgressStatus);
    }

    // Logo 淡入动画
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOutCubic,
    );

    // 文字淡入动画（延迟于 logo）
    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFadeAnimation = CurvedAnimation(
      parent: _textFadeController,
      curve: Curves.easeOutCubic,
    );

    // Logo 呼吸动画：缓慢缩放脉动
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _breatheScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    // 启动动画序列
    _fadeInController.forward().then((_) {
      _textFadeController.forward();
      _progressController.forward();
      _breatheController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_handleProgressStatus);
    _progressController.dispose();
    _fadeInController.dispose();
    _textFadeController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  void _handleProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _enterApp();
    }
  }

  void _enterApp() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.corkBoard,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: AnimatedBuilder(
                      animation: _breatheScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _breatheScale.value,
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/images/splash_logo.png',
                        width: (constraints.maxWidth + 64).clamp(320.0, 560.0),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Text(
                      'RETICENCE',
                      style: TextStyle(
                        color: AppColors.agedPaper.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: SizedBox(
                      width: 92,
                      height: 2,
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return LinearProgressIndicator(
                            value: _progressController.value,
                            backgroundColor:
                                AppColors.corkBoardLight.withValues(alpha: 0.45),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.redThread.withValues(alpha: 0.9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
