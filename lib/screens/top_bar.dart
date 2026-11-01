import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'tool_buttons.dart';

/// 顶部栏组件
///
/// 包含应用标题 "RETICENCE" 和搜索按钮/搜索框。
/// 搜索栏展开时显示输入框，收起时显示标题和搜索图标。
/// 仅在有卡片时显示搜索按钮（空状态无需搜索）。
/// 使用 AnimatedSwitcher 实现标题/搜索框的平滑切换。
class TopBar extends StatefulWidget {
  final bool showSearch;
  final TextEditingController searchController;
  final int cardCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchToggle;

  const TopBar({
    super.key,
    required this.showSearch,
    required this.searchController,
    required this.cardCount,
    required this.onSearchChanged,
    required this.onSearchToggle,
  });

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
    widget.searchController.addListener(_onSearchTextChanged);
    _hasText = widget.searchController.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onSearchTextChanged);
      widget.searchController.addListener(_onSearchTextChanged);
      _hasText = widget.searchController.text.isNotEmpty;
    }
  }

  void _onSearchTextChanged() {
    final hasText = widget.searchController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchTextChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: widget.showSearch ? 8 : 10,
          ),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: widget.showSearch
                          ? const SizedBox(key: ValueKey('spacer'))
                          : Semantics(
                              key: const ValueKey('title'),
                              label: '应用标题 RETICENCE',
                              child: Text(
                                'RETICENCE',
                                style: TextStyle(
                                  color: AppColors.agedPaper
                                      .withValues(alpha: 0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (widget.cardCount > 0)
                    ToolButton(
                      icon: widget.showSearch ? Icons.close : Icons.search,
                      onTap: widget.onSearchToggle,
                      color: AppColors.agedPaper.withValues(alpha: 0.85),
                      size: 36,
                      iconSize: 18,
                      semanticLabel: widget.showSearch ? '关闭搜索' : '搜索线索',
                      tooltip: widget.showSearch ? '关闭搜索' : '搜索线索',
                    ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: widget.showSearch
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.agedPaper.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isSearchFocused
                                  ? AppColors.redThread.withValues(alpha: 0.35)
                                  : AppColors.sepia.withValues(alpha: 0.3),
                              width: _isSearchFocused ? 1.2 : 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isSearchFocused
                                    ? AppColors.redThread.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.15),
                                blurRadius: _isSearchFocused ? 12 : 8,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color:
                                    AppColors.sepia.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: widget.searchController,
                            focusNode: _searchFocusNode,
                            onChanged: widget.onSearchChanged,
                            style: const TextStyle(
                              color: AppColors.inkBlack,
                              fontSize: 14,
                            ),
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: '搜索线索、类型或关系...',
                              hintStyle: TextStyle(
                                color: AppColors.sepia.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.sepia.withValues(alpha: 0.6),
                                size: 18,
                              ),
                              suffixIcon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.7, end: 1.0)
                                          .animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _hasText
                                    ? GestureDetector(
                                        key: const ValueKey('clear'),
                                        onTap: () {
                                          widget.searchController.clear();
                                          widget.onSearchChanged('');
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: AppColors.sepia
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(
                                        key: ValueKey('empty')),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
