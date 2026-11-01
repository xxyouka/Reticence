/// 连线 Provider 模块
///
/// 本文件定义了线索墙中「连线」（Connection）相关的 Riverpod 状态管理。
/// 核心职责包括：
/// - 提供 [ConnectionRepository] 的依赖注入实例
/// - 通过 [ConnectionListNotifier] 管理连线的完整 CRUD 生命周期
/// - 通过 [connectionErrorProvider] 暴露操作错误信息供 UI 层消费
///
/// 连线表示两张线索卡片之间的关联关系，在线索墙上以绳线/线条的形式呈现。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_model.dart';
import '../theme/wall_constants.dart';
import '../services/database/database_provider.dart';
import '../services/repositories/connection_repository.dart';

/// 连线仓库 Provider
///
/// 依赖 [appDatabaseProvider] 获取数据库实例，从中取出 [ConnectionDao]，
/// 构造并暴露 [ConnectionRepository] 供其他 Provider 使用。
/// 使用 `ref.watch` 监听数据库变化，数据库重建时仓库也会随之重建。
final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ConnectionRepository(db.connectionDao);
});

/// 连线列表 Provider
///
/// 提供 [List<Connection>] 类型的异步状态，由 [ConnectionListNotifier] 管理。
/// UI 层通过 `ref.watch(connectionListProvider)` 监听连线列表变化，
/// 自动响应增删操作带来的列表刷新。
final connectionListProvider =
    AsyncNotifierProvider<ConnectionListNotifier, List<Connection>>(
        ConnectionListNotifier.new);

/// 连线错误信息 Provider
///
/// 持有最近一次连线操作的错误描述字符串，无错误时为 `null`。
/// UI 层可监听此 Provider 来展示 SnackBar 或错误提示。
final connectionErrorProvider = StateProvider<String?>((ref) => null);

/// 连线列表通知器
///
/// 继承 [AsyncNotifier]，管理 [List<Connection>] 的异步状态。
/// 生命周期：
/// 1. [build] 方法在 Provider 首次被监听时调用，从数据库加载全部连线
/// 2. 增删改操作先更新内存中的 state，再异步写入数据库
///
/// 与卡片不同，连线没有「拖拽中仅更新内存」的需求，
/// 因为连线位置由其两端卡片的坐标决定，不需要独立的位置更新逻辑。
class ConnectionListNotifier extends AsyncNotifier<List<Connection>> {
  /// 初始化：从数据库加载全部连线
  ///
  /// 使用 `ref.watch` 监听 [connectionRepositoryProvider]，当仓库实例变化时
  /// 会自动重新加载数据。加载失败时将错误写入 [connectionErrorProvider]，
  /// 并返回空列表作为降级处理，避免 state 进入错误态导致 UI 崩溃。
  @override
  Future<List<Connection>> build() async {
    final repo = ref.watch(connectionRepositoryProvider);
    try {
      return await repo.getAllConnections();
    } catch (e) {
      ref.read(connectionErrorProvider.notifier).state = '加载连线失败: $e';
      return [];
    }
  }

  /// 添加一条连线
  ///
  /// 将连线插入数据库，成功后将返回的（含自增 id 的）新连线
  /// 追加到当前列表末尾，并更新 state。返回新连线对象，失败返回 `null`。
  Future<Connection?> addConnection(Connection connection) async {
    final currentCount = state.value?.length ?? 0;
    if (currentCount >= WallConstants.maxConnections) {
      ref.read(connectionErrorProvider.notifier).state =
          '已达连线数量上限（${WallConstants.maxConnections}）';
      return null;
    }
    try {
      final repo = ref.read(connectionRepositoryProvider);
      final newConn = await repo.insertConnection(connection);
      state = AsyncValue.data([...?state.value, newConn]);
      return newConn;
    } catch (e) {
      ref.read(connectionErrorProvider.notifier).state = '添加连线失败: $e';
      return null;
    }
  }

  /// 更新一条连线的全部字段
  ///
  /// 先将更新后的连线写入数据库，再在内存列表中替换对应 id 的连线。
  /// 返回 `true` 表示成功，`false` 表示失败。
  Future<bool> updateConnection(Connection connection) async {
    try {
      final repo = ref.read(connectionRepositoryProvider);
      await repo.updateConnection(connection);
      state = AsyncValue.data(
        state.value
                ?.map((c) => c.id == connection.id ? connection : c)
                .toList() ??
            [],
      );
      return true;
    } catch (e) {
      ref.read(connectionErrorProvider.notifier).state = '更新连线失败: $e';
      return false;
    }
  }

  /// 删除指定 id 的连线
  ///
  /// 先从数据库删除，再从内存列表中移除对应连线。
  /// 返回 `true` 表示成功，`false` 表示失败。
  Future<bool> deleteConnection(int id) async {
    try {
      final repo = ref.read(connectionRepositoryProvider);
      await repo.deleteConnection(id);
      state = AsyncValue.data(
        state.value?.where((c) => c.id != id).toList() ?? [],
      );
      return true;
    } catch (e) {
      ref.read(connectionErrorProvider.notifier).state = '删除连线失败: $e';
      return false;
    }
  }
}
