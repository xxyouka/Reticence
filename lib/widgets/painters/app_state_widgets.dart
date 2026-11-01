/// 应用状态组件库
///
/// 提供侦探线索墙应用中通用的加载状态和错误状态展示组件。
/// 这些组件用于在异步数据加载过程中向用户提供视觉反馈，
/// 避免界面出现空白或无响应的情况。
///
/// 包含两个组件：
/// - [AppErrorWidget]：错误状态展示，支持可选的重试按钮
/// - [AppLoadingWidget]：加载状态展示，支持可选的提示文字
///
/// 设计理念：即使是状态提示组件也融入侦探主题的视觉元素。
/// - 错误图标和加载指示器使用红线色（redThread），呼应"红线"主题
/// - 文字使用墨黑色，保持与整体应用的墨水笔迹风格一致
/// - 重试按钮使用红线色实心样式，与对话框中的主操作按钮风格统一
library;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/app_haptics.dart';
import '../dialogs/app_dialog_components.dart';

/// 错误状态展示组件
///
/// 在数据加载失败或操作异常时显示，包含：
/// - 错误图标（红色轮廓风格）
/// - 错误信息文字
/// - 可选的重试按钮
///
/// 使用场景：网络请求失败、数据解析异常、空数据等。
/// 当提供 [onRetry] 回调时，会显示"重试"按钮，点击后触发轻量触觉反馈。
class AppErrorWidget extends StatelessWidget {
  /// 错误信息文字
  final String message;

  /// 重试按钮的回调，为 null 时不显示重试按钮
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 错误图标：使用红线色，呼应侦探主题中的"红线"意象
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.redThread,
            ),
            const SizedBox(height: 16),
            // 错误信息文字
            Text(
              message,
              style: TextStyle(
                color: AppColors.inkBlack.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            // 重试按钮：仅当提供了 onRetry 回调时显示
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                child: AppActionButton(
                  label: '重试',
                  color: AppColors.redThread.withValues(alpha: 0.88),
                  filled: true,
                  onTap: () {
                    AppHaptics.light();
                    onRetry!();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 加载状态展示组件
///
/// 在数据异步加载过程中显示，包含：
/// - 圆形进度指示器（红线色）
/// - 可选的加载提示文字
///
/// 使用场景：初始数据加载、卡片列表刷新、连线数据获取等。
/// 进度指示器使用红线色，与侦探主题的"红线"意象保持一致。
class AppLoadingWidget extends StatelessWidget {
  /// 加载提示文字，为 null 时不显示文字
  final String? message;

  const AppLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 2,
              child: LinearProgressIndicator(
                backgroundColor:
                    AppColors.corkBoardLight.withValues(alpha: 0.45),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.redThread.withValues(alpha: 0.9),
                ),
              ),
            ),
            // 加载提示文字：仅当提供了 message 时显示
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  color: AppColors.inkBlack.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
