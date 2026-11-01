/// 照片仓库模块
///
/// 本文件实现了 [PhotoRepository] 类，采用 Repository 模式封装照片数据的持久化操作。
/// 作为业务层（Model）与数据访问层（DAO）之间的桥梁，负责：
/// - 将 Drift 生成的数据实体（PhotosTableData）转换为业务模型（PhotoCard）
/// - 将业务模型（PhotoCard）转换为 Drift 的 Companion 对象用于写入操作
/// - 处理可空字段（caption）的 null 写回
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/photo_dao.dart';
import '../../models/photo_card_model.dart';

/// 照片数据仓库
///
/// 封装 [PhotoDao] 的数据访问操作，提供面向业务层的增删改查接口。
/// 核心职责是处理数据层实体与业务模型之间的转换，特别是：
/// - type 字段使用枚举索引（int）存储，需双向转换
/// - 多个可空字段需要显式写入 null，避免更新时无法清空旧值
class PhotoRepository {
  /// 照片数据访问对象
  final PhotoDao photoDao;

  PhotoRepository(this.photoDao);

  /// 将业务模型转换为 Drift Companion 对象
  ///
  /// 核心转换逻辑：
  /// - **id 字段**：如果为 null 则使用 [Value.absent]，让数据库自动生成自增 ID；
  ///   如果不为 null 则使用 [Value] 包装，用于更新操作
  /// - **可空字段**（caption）：
  ///   始终使用 [Value] 包装，包含 null。这样更新时能真正把旧值清空为 SQL NULL。
  PhotosTableCompanion _toCompanion(PhotoCard photo) {
    return PhotosTableCompanion(
      id: photo.id != null ? Value(photo.id!) : const Value.absent(),
      imagePath: Value(photo.imagePath),
      caption: Value(photo.caption),
      x: Value(photo.x),
      y: Value(photo.y),
      rotation: Value(photo.rotation),
      width: Value(photo.width),
      height: Value(photo.height),
      photoStyle: Value(photo.photoStyle.index),
      createdAt: Value(photo.createdAt),
      updatedAt: Value(photo.updatedAt),
    );
  }

  /// 将 Drift 数据实体转换为业务模型
  PhotoCard _toModel(PhotosTableData data) {
    final styleIndex = data.photoStyle;
    final photoStyle = styleIndex >= 0 && styleIndex < PhotoStyle.values.length
        ? PhotoStyle.values[styleIndex]
        : PhotoStyle.polaroid;
    return PhotoCard(
      id: data.id,
      imagePath: data.imagePath,
      caption: data.caption,
      x: data.x,
      y: data.y,
      rotation: data.rotation,
      width: data.width,
      height: data.height,
      photoStyle: photoStyle,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// 获取所有照片
  ///
  /// 返回业务模型 [PhotoCard] 列表，将数据库实体逐个转换为业务模型
  Future<List<PhotoCard>> getAllPhotos() async {
    final data = await photoDao.getAllPhotos();
    return data.map(_toModel).toList();
  }

  /// 插入新照片
  ///
  /// 将业务模型转换为 Companion 对象后插入数据库，
  /// 返回带有数据库生成 ID 的新照片实例
  Future<PhotoCard?> insertPhoto(PhotoCard photo) async {
    final id = await photoDao.insertPhoto(_toCompanion(photo));
    return photo.copyWith(id: id);
  }

  /// 更新已有照片
  ///
  /// 将业务模型转换为 Companion 对象后执行更新操作。
  /// 注意：更新时强制覆盖 id 和 updatedAt 字段：
  /// - [id] 使用 [Value] 包装确保 WHERE 子句能定位到正确记录
  /// - [updatedAt] 自动设置为当前时间，记录最后修改时间
  Future<bool> updatePhoto(PhotoCard photo) async {
    return await photoDao.updatePhoto(_toCompanion(photo).copyWith(
      // 确保 id 被包含在更新条件中
      id: Value(photo.id!),
      // 自动更新修改时间
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 根据 ID 删除照片
  ///
  /// [id] 照片主键
  Future<void> deletePhoto(int id) async {
    await photoDao.deletePhoto(id);
  }
}
