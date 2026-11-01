/// 关系网络聚焦徽章
///
/// 聚焦模式下显示当前线索名称和退出入口，点击徽章退出聚焦。
/// 位于顶部图例下方，使用与搜索徽章一致的旧纸质感。
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class FocusModeBadge extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const FocusModeBadge({
    super.key,
    required this.label,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 102;

    return Positioned(
      top: top,
      left: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.94 + 0.06 * value,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          );
        },
        child: Semantics(
          button: true,
          label: '退出聚焦网络，当前聚焦 $label',
          hint: '点击退出',
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.agedPaper.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.sepia.withValues(alpha: 0.35),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppColors.redThread.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.center_focus_strong,
                    size: 14,
                    color: AppColors.redThread.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Text(
                      '聚焦 · $label',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.harmonyOS,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkBlack.withValues(alpha: 0.78),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.close,
                    size: 13,
                    color: AppColors.sepia.withValues(alpha: 0.55),
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
