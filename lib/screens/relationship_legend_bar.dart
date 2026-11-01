/// 关系图例筛选条
///
/// 常驻在顶部栏下方的轻量图例：四种关系类型各显示颜色圆点、名称和数量。
/// 点击类型即可只看该类关系，再次点击恢复；点击"全部"清除筛选。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_model.dart';
import '../providers/connection_provider.dart';
import '../providers/relationship_filter_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/clue_type_style.dart';
import '../utils/app_haptics.dart';

class RelationshipLegendBar extends ConsumerWidget {
  const RelationshipLegendBar({super.key});

  static const double _chipGap = 4;
  static const double _barHeight = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections =
        ref.watch(connectionListProvider).value ?? const <Connection>[];
    if (connections.isEmpty) return const SizedBox.shrink();

    final counts = <ConnectionType, int>{
      for (final type in ConnectionType.values) type: 0,
    };
    for (final connection in connections) {
      counts[connection.connectionType] =
          counts[connection.connectionType]! + 1;
    }

    final filter = ref.watch(relationshipFilterProvider);

    return SizedBox(
      height: _barHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const _LegendLabel(),
            const SizedBox(width: 8),
            _LegendChip(
              key: const ValueKey('relationship-legend-all'),
              label: '全部',
              count: connections.length,
              color: AppColors.sepia,
              selected: filter.isEmpty,
              enabled: true,
              onTap: () {
                ref.read(relationshipFilterProvider.notifier).state =
                    const <ConnectionType>{};
              },
            ),
            const SizedBox(width: _chipGap),
            for (final type in ConnectionType.values) ...[
              _LegendChip(
                key: ValueKey('relationship-legend-${type.name}'),
                label: type.label,
                count: counts[type]!,
                color: type.color,
                selected: filter.isEmpty || filter.contains(type),
                enabled: counts[type]! > 0 || filter.contains(type),
                onTap: () {
                  final current = ref.read(relationshipFilterProvider);
                  ref.read(relationshipFilterProvider.notifier).state =
                      toggleRelationshipFilter(current, type);
                },
              ),
              if (type != ConnectionType.values.last)
                const SizedBox(width: _chipGap),
            ],
          ],
        ),
      ),
    );
  }
}

/// 图例条的前置说明
class _LegendLabel extends StatelessWidget {
  const _LegendLabel();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: '关系图例与筛选',
      child: Text(
        '关系',
        style: TextStyle(
          fontFamily: AppTypography.harmonyOS,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: AppColors.agedPaper.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// 单个图例选项 —— 颜色圆点 + 名称 + 数量
class _LegendChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _LegendChip({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '$label关系，$count 条${selected ? '，已显示' : '，已淡化'}',
      child: GestureDetector(
        onTap: enabled
            ? () {
                AppHaptics.selection();
                onTap();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.18)
                : AppColors.agedPaper.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.55)
                  : AppColors.sepia.withValues(alpha: 0.18),
              width: selected ? 1.2 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected ? 1 : 0.35),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.harmonyOS,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.inkBlack
                      .withValues(alpha: selected ? 0.85 : 0.5),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: AppTypography.harmonyOS,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkBlack
                      .withValues(alpha: selected ? 0.5 : 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.45,
      child: chip,
    );
  }
}
