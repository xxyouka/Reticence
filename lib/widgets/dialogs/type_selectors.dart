/// 类型选择器组件
///
/// 为「新建/编辑线索」和「编辑关系」提供统一的类型选择交互。
/// 每个选项由图标、中文标签和类型色组成，选中时填充类型色并加粗描边。
library;

import 'package:flutter/material.dart';

import '../../models/card_model.dart';
import '../../models/connection_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/clue_type_style.dart';
import '../../utils/app_haptics.dart';

/// 线索类型选择器：人物 / 地点 / 事件
class ClueTypeSelector extends StatelessWidget {
  final CardType selected;
  final ValueChanged<CardType> onChanged;

  const ClueTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SelectorLabel(text: '线索类型'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final type in CardType.values) ...[
              if (type != CardType.values.first) const SizedBox(width: 8),
              Expanded(
                child: TypeOptionChip(
                  icon: type.icon,
                  label: type.label,
                  color: type.color,
                  selected: type == selected,
                  onTap: () => onChanged(type),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// 关系类型选择器：中立 / 盟友 / 敌对 / 自定义
class RelationshipTypeSelector extends StatelessWidget {
  final ConnectionType selected;
  final ValueChanged<ConnectionType> onChanged;

  const RelationshipTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SelectorLabel(text: '关系类型'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in ConnectionType.values)
              TypeOptionChip(
                icon: type.icon,
                label: type.label,
                color: type.color,
                selected: type == selected,
                onTap: () => onChanged(type),
              ),
          ],
        ),
      ],
    );
  }
}

/// 单个类型选项 —— 图标 + 标签，选中时使用类型色强调
class TypeOptionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const TypeOptionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label类型${selected ? '，已选中' : ''}',
      child: GestureDetector(
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.14)
                : AppColors.agedPaper.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.55)
                  : AppColors.sepia.withValues(alpha: 0.18),
              width: selected ? 1.3 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? color.withValues(alpha: 0.9)
                    : AppColors.sepia.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.harmonyOS,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.inkBlack.withValues(alpha: 0.85)
                      : AppColors.inkBlack.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorLabel extends StatelessWidget {
  final String text;

  const _SelectorLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTypography.harmonyOS,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.sepia.withValues(alpha: 0.55),
      ),
    );
  }
}
