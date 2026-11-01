/// 照片卡片 Provider 模块
///
/// 本文件定义了线索墙中「照片卡片」相关的 Riverpod 状态管理。
/// 核心职责包括：
/// - 提供 [PhotoRepository] 的依赖注入实例
/// - 通过 [PhotoListNotifier] 管理照片卡片的完整 CRUD 生命周期
/// - 实现拖拽场景下的「内存即时更新 + 延迟持久化」双阶段位置更新策略，
///   确保拖拽时 UI 流畅无卡顿，松手后才写入数据库
/// - 通过 [photoErrorProvider] 暴露操作错误信息供 UI 层消费
///
/// 照片卡片与线索卡片类似，都可在线索墙上自由拖拽定位，
/// 但照片卡片额外关联了图片资源。
library;

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/photo_card_model.dart';
import '../services/database/database_provider.dart';
import '../services/repositories/photo_repository.dart';
import '../theme/wall_constants.dart';

/// 照片仓库 Provider
///
/// 依赖 [appDatabaseProvider] 获取数据库实例，从中取出 [PhotoDao]，
/// 构造并暴露 [PhotoRepository] 供其他 Provider 使用。
/// 使用 `ref.watch` 监听数据库变化，数据库重建时仓库也会随之重建。
final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PhotoRepository(db.photoDao);
});

/// 照片列表 Provider
///
/// 提供 [List<PhotoCard>] 类型的异步状态，由 [PhotoListNotifier] 管理。
/// UI 层通过 `ref.watch(photoListProvider)` 监听照片列表变化，
/// 自动响应增删改操作带来的列表刷新。
final photoListProvider =
    AsyncNotifierProvider<PhotoListNotifier, List<PhotoCard>>(
        PhotoListNotifier.new);

/// 照片错误信息 Provider
///
/// 持有最近一次照片操作的错误描述字符串，无错误时为 `null`。
/// UI 层可监听此 Provider 来展示 SnackBar 或错误提示。
final photoErrorProvider = StateProvider<String?>((ref) => null);

/// 照片卡片列表通知器
///
/// 继承 [AsyncNotifier]，管理 [List<PhotoCard>] 的异步状态。
/// 生命周期：
/// 1. [build] 方法在 Provider 首次被监听时调用，从数据库加载全部照片卡片
/// 2. 增删改操作先更新内存中的 state，再异步写入数据库
/// 3. 位置更新采用双阶段策略：拖拽中仅更新内存（[updatePhotoPositionInMemory]），
///    拖拽结束后才持久化到数据库（[persistPhotoPosition]）
///
/// 这种设计避免了拖拽过程中频繁的数据库 I/O 导致的 UI 卡顿。
class PhotoListNotifier extends AsyncNotifier<List<PhotoCard>> {
  /// 初始化：从数据库加载全部照片卡片
  ///
  /// 使用 `ref.watch` 监听 [photoRepositoryProvider]，当仓库实例变化时
  /// 会自动重新加载数据。加载失败时将错误写入 [photoErrorProvider]，
  /// 并返回空列表作为降级处理，避免 state 进入错误态导致 UI 崩溃。
  @override
  Future<List<PhotoCard>> build() async {
    final repo = ref.watch(photoRepositoryProvider);
    try {
      return await repo.getAllPhotos();
    } catch (e) {
      ref.read(photoErrorProvider.notifier).state = '加载照片失败: $e';
      return [];
    }
  }

  /// 添加一张照片卡片
  ///
  /// 将照片卡片插入数据库，成功后将返回的（含自增 id 的）新照片卡片
  /// 追加到当前列表末尾，并更新 state。返回新照片对象，失败返回 `null`。
  Future<PhotoCard?> addPhoto(PhotoCard photo) async {
    final currentCount = state.value?.length ?? 0;
    if (currentCount >= WallConstants.maxPhotos) {
      ref.read(photoErrorProvider.notifier).state =
          '已达照片数量上限（${WallConstants.maxPhotos}）';
      return null;
    }
    try {
      final repo = ref.read(photoRepositoryProvider);
      final newPhoto = await repo.insertPhoto(photo);
      if (newPhoto == null) {
        ref.read(photoErrorProvider.notifier).state = '添加照片失败：数据库未返回数据';
        return null;
      }
      state = AsyncValue.data([...?state.value, newPhoto]);
      return newPhoto;
    } catch (e) {
      ref.read(photoErrorProvider.notifier).state = '添加照片失败: $e';
      return null;
    }
  }

  /// 更新一张照片卡片的全部字段
  ///
  /// 先将更新后的照片卡片写入数据库，再在内存列表中替换对应 id 的照片。
  /// 返回 `true` 表示成功，`false` 表示失败。
  Future<bool> updatePhoto(PhotoCard photo) async {
    try {
      final repo = ref.read(photoRepositoryProvider);
      await repo.updatePhoto(photo);
      state = AsyncValue.data(
        state.value?.map((p) => p.id == photo.id ? photo : p).toList() ?? [],
      );
      return true;
    } catch (e) {
      ref.read(photoErrorProvider.notifier).state = '更新照片失败: $e';
      return false;
    }
  }

  /// 仅更新内存中的照片位置（不写数据库）
  ///
  /// 此方法专为拖拽场景设计：用户拖动照片卡片时，每帧都会调用此方法
  /// 更新照片的 (x, y) 坐标。由于仅修改内存中的 state，不触发数据库 I/O，
  /// 因此可以保证 60fps 的流畅拖拽体验。
  ///
  /// 拖拽结束后，应调用 [persistPhotoPosition] 将最终位置写入数据库。
  void updatePhotoPositionInMemory(int photoId, double x, double y) {
    final photos = state.value;
    if (photos == null) return;
    state = AsyncValue.data([
      for (final p in photos)
        if (p.id == photoId)
          p.copyWith(x: x, y: y, updatedAt: DateTime.now())
        else
          p,
    ]);
  }

  /// 更新照片位置（内存 + 数据库同步更新）
  ///
  /// 一次性完成内存更新和数据库持久化的便捷方法，
  /// 适用于撤销/重做等需要同时更新位置的场景。
  Future<void> updatePhotoPosition(int photoId, double x, double y) async {
    final photos = state.value;
    if (photos == null) return;
    final photo = photos.firstWhereOrNull((p) => p.id == photoId);
    if (photo == null) return;
    final updated = photo.copyWith(x: x, y: y, updatedAt: DateTime.now());
    await updatePhoto(updated);
  }

  /// 将内存中的照片位置持久化到数据库
  ///
  /// 在拖拽结束（松手）时调用。从当前内存 state 中读取指定照片的最新位置，
  /// 然后通过仓库写入数据库。此方法不会修改内存 state，
  /// 因为位置已经在 [updatePhotoPositionInMemory] 中更新过了。
  Future<void> persistPhotoPosition(int photoId) async {
    final photos = state.value;
    if (photos == null) return;
    final photo = photos.firstWhereOrNull((p) => p.id == photoId);
    if (photo == null) return;
    try {
      final repo = ref.read(photoRepositoryProvider);
      await repo.updatePhoto(photo);
    } catch (e) {
      ref.read(photoErrorProvider.notifier).state = '保存位置失败: $e';
    }
  }

  /// 删除指定 id 的照片卡片
  ///
  /// 先从数据库删除，再从内存列表中移除对应照片。
  /// 返回 `true` 表示成功，`false` 表示失败。
  Future<bool> deletePhoto(int id) async {
    try {
      final repo = ref.read(photoRepositoryProvider);
      await repo.deletePhoto(id);
      state = AsyncValue.data(
        state.value?.where((p) => p.id != id).toList() ?? [],
      );
      return true;
    } catch (e) {
      ref.read(photoErrorProvider.notifier).state = '删除照片失败: $e';
      return false;
    }
  }
}
