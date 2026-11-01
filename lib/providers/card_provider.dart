/// 线索卡片 Provider 模块
///
/// 本文件定义了线索墙（Clue Wall）中「线索卡片」相关的 Riverpod 状态管理。
/// 核心职责包括：
/// - 提供 [CardRepository] 的依赖注入实例
/// - 通过 [CardListNotifier] 管理线索卡片的完整 CRUD 生命周期
/// - 实现拖拽场景下的「内存即时更新 + 延迟持久化」双阶段位置更新策略，
///   确保拖拽时 UI 流畅无卡顿，松手后才写入数据库
/// - 通过 [cardErrorProvider] 暴露操作错误信息供 UI 层消费
library;

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_model.dart';
import '../theme/wall_constants.dart';
import '../services/database/database_provider.dart';
import '../services/repositories/card_repository.dart';

/// 卡片仓库 Provider
///
/// 依赖 [appDatabaseProvider] 获取数据库实例，从中取出 [CardDao]，
/// 构造并暴露 [CardRepository] 供其他 Provider 使用。
/// 使用 `ref.watch` 监听数据库变化，数据库重建时仓库也会随之重建。
final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CardRepository(db.cardDao);
});

/// 卡片列表 Provider
///
/// 提供 [List<ClueCard>] 类型的异步状态，由 [CardListNotifier] 管理。
/// UI 层通过 `ref.watch(cardListProvider)` 监听卡片列表变化，
/// 自动响应增删改操作带来的列表刷新。
final cardListProvider =
    AsyncNotifierProvider<CardListNotifier, List<ClueCard>>(
        CardListNotifier.new);

/// 卡片错误信息 Provider
///
/// 持有最近一次卡片操作的错误描述字符串，无错误时为 `null`。
/// UI 层可监听此 Provider 来展示 SnackBar 或错误提示。
final cardErrorProvider = StateProvider<String?>((ref) => null);

/// 线索卡片列表通知器
///
/// 继承 [AsyncNotifier]，管理 [List<ClueCard>] 的异步状态。
/// 生命周期：
/// 1. [build] 方法在 Provider 首次被监听时调用，从数据库加载全部卡片
/// 2. 增删改操作先更新内存中的 state，再异步写入数据库
/// 3. 位置更新采用双阶段策略：拖拽中仅更新内存（[updateCardPositionInMemory]），
///    拖拽结束后才持久化到数据库（[persistCardPosition]）
///
/// 这种设计避免了拖拽过程中频繁的数据库 I/O 导致的 UI 卡顿。
class CardListNotifier extends AsyncNotifier<List<ClueCard>> {
  /// 初始化：从数据库加载全部线索卡片
  ///
  /// 使用 `ref.watch` 监听 [cardRepositoryProvider]，当仓库实例变化时
  /// 会自动重新加载数据。加载失败时将错误写入 [cardErrorProvider]，
  /// 并返回空列表作为降级处理，避免 state 进入错误态导致 UI 崩溃。
  @override
  Future<List<ClueCard>> build() async {
    final repo = ref.watch(cardRepositoryProvider);
    try {
      return await repo.getAllCards();
    } catch (e) {
      ref.read(cardErrorProvider.notifier).state = '加载卡片失败: $e';
      return [];
    }
  }

  /// 添加一张线索卡片
  ///
  /// 将卡片插入数据库，成功后将返回的（含自增 id 的）新卡片
  /// 追加到当前列表末尾，并更新 state。返回新卡片对象，失败返回 `null`。
  Future<ClueCard?> addCard(ClueCard card) async {
    final currentCount = state.value?.length ?? 0;
    if (currentCount >= WallConstants.maxCards) {
      ref.read(cardErrorProvider.notifier).state =
          '已达卡片数量上限（${WallConstants.maxCards}）';
      return null;
    }
    try {
      final repo = ref.read(cardRepositoryProvider);
      final newCard = await repo.insertCard(card);
      state = AsyncValue.data([...?state.value, newCard]);
      return newCard;
    } catch (e) {
      ref.read(cardErrorProvider.notifier).state = '添加卡片失败: $e';
      return null;
    }
  }

  /// 更新一张线索卡片的全部字段
  ///
  /// 先将更新后的卡片写入数据库，再在内存列表中替换对应 id 的卡片。
  /// 返回 `true` 表示成功，`false` 表示失败。
  Future<bool> updateCard(ClueCard card) async {
    try {
      final repo = ref.read(cardRepositoryProvider);
      await repo.updateCard(card);
      state = AsyncValue.data(
        state.value?.map((c) => c.id == card.id ? card : c).toList() ?? [],
      );
      return true;
    } catch (e) {
      ref.read(cardErrorProvider.notifier).state = '更新卡片失败: $e';
      return false;
    }
  }

  /// 仅更新内存中的卡片位置（不写数据库）
  ///
  /// 此方法专为拖拽场景设计：用户拖动卡片时，每帧都会调用此方法
  /// 更新卡片的 (x, y) 坐标。由于仅修改内存中的 state，不触发数据库 I/O，
  /// 因此可以保证 60fps 的流畅拖拽体验。
  ///
  /// 拖拽结束后，应调用 [persistCardPosition] 将最终位置写入数据库。
  void updateCardPositionInMemory(int cardId, double x, double y) {
    final cards = state.value;
    if (cards == null) return;
    state = AsyncValue.data([
      for (final c in cards)
        if (c.id == cardId)
          c.copyWith(x: x, y: y, updatedAt: DateTime.now())
        else
          c,
    ]);
  }

  /// 将内存中的卡片位置持久化到数据库
  ///
  /// 在拖拽结束（松手）时调用。从当前内存 state 中读取指定卡片的最新位置，
  /// 然后通过仓库写入数据库。此方法不会修改内存 state，
  /// 因为位置已经在 [updateCardPositionInMemory] 中更新过了。
  Future<void> persistCardPosition(int cardId) async {
    final cards = state.value;
    if (cards == null) return;
    final card = cards.where((c) => c.id == cardId).firstOrNull;
    if (card == null) return;
    try {
      final repo = ref.read(cardRepositoryProvider);
      await repo.updateCard(card);
    } catch (e) {
      ref.read(cardErrorProvider.notifier).state = '保存位置失败: $e';
    }
  }

  /// 更新卡片位置（内存 + 数据库同步更新）
  ///
  /// 这是一次性完成内存更新和数据库持久化的便捷方法，
  /// 适用于非拖拽场景的位置变更（如自动布局、吸附对齐等）。
  /// 拖拽场景请使用 [updateCardPositionInMemory] + [persistCardPosition] 的组合。
  Future<void> updateCardPosition(int cardId, double x, double y) async {
    final cards = state.value;
    if (cards == null) return;
    final card = cards.firstWhereOrNull((c) => c.id == cardId);
    if (card == null) return;
    final updated = card.copyWith(x: x, y: y, updatedAt: DateTime.now());
    await updateCard(updated);
  }

  /// 删除指定 id 的线索卡片
  ///
  /// 先从数据库删除，再从内存列表中移除对应卡片。
  /// 返回 `true` 表示成功，`false` 表示失败。
  Future<bool> deleteCard(int id) async {
    try {
      final repo = ref.read(cardRepositoryProvider);
      await repo.deleteCard(id);
      state = AsyncValue.data(
        state.value?.where((c) => c.id != id).toList() ?? [],
      );
      return true;
    } catch (e) {
      ref.read(cardErrorProvider.notifier).state = '删除卡片失败: $e';
      return false;
    }
  }
}
