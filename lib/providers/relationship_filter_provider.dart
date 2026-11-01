/// 关系类型筛选状态
///
/// 空集合表示"全部关系"，否则只展示集合中的关系类型。
/// 筛选只影响红线的显示与命中，不改变卡片、照片和数据本身。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_model.dart';

/// 当前选中的关系类型；空集合 = 全部显示
final relationshipFilterProvider =
    StateProvider<Set<ConnectionType>>((ref) => const <ConnectionType>{});

/// 某关系类型在当前筛选下是否可见
bool isConnectionTypeVisible(
  ConnectionType type,
  Set<ConnectionType> filter,
) =>
    filter.isEmpty || filter.contains(type);

/// 切换某个关系类型的筛选状态
///
/// 交互规则：
/// - 当前为"全部"时，点选某类型 → 只看该类型
/// - 已选某类型时再点它 → 回到"全部"
/// - 多选累计到全部四种 → 自动回到"全部"
Set<ConnectionType> toggleRelationshipFilter(
  Set<ConnectionType> current,
  ConnectionType type,
) {
  if (current.isEmpty) return {type};

  final next = Set<ConnectionType>.of(current);
  if (!next.remove(type)) {
    next.add(type);
  }

  if (next.isEmpty || next.length == ConnectionType.values.length) {
    return const <ConnectionType>{};
  }
  return next;
}
