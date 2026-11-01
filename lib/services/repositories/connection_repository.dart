/// 卡片关联仓库模块
///
/// 本文件实现了 [ConnectionRepository] 类，采用 Repository 模式封装卡片关联数据的持久化操作。
/// 作为业务层（Model）与数据访问层（DAO）之间的桥梁，负责：
/// - 将 Drift 生成的数据实体（ConnectionsTableData）转换为业务模型（Connection）
/// - 将业务模型（Connection）转换为 Drift 的 Companion 对象用于写入操作
library;

import 'package:drift/drift.dart';

import '../../models/connection_model.dart';
import '../database/app_database.dart';
import '../database/daos/connection_dao.dart';

/// 卡片关联数据仓库
///
/// 封装 [ConnectionDao] 的数据访问操作，提供面向业务层的增删改查接口。
class ConnectionRepository {
  /// 关联数据访问对象
  final ConnectionDao _dao;

  ConnectionRepository(this._dao);

  /// 获取所有关联
  ///
  /// 返回业务模型 [Connection] 列表，将数据库实体逐个转换为业务模型
  Future<List<Connection>> getAllConnections() async {
    final data = await _dao.getAllConnections();
    return data.map(_toModel).toList();
  }

  /// 获取指定卡片的所有关联
  ///
  /// [cardId] 卡片主键，查询该卡片作为起始或目标的所有关联
  Future<List<Connection>> getConnectionsForCard(int cardId) async {
    final data = await _dao.getConnectionsForCard(cardId);
    return data.map(_toModel).toList();
  }

  /// 获取指定照片的所有关联
  ///
  /// [photoId] 照片主键，查询该照片作为起始或目标的所有关联
  Future<List<Connection>> getConnectionsForPhoto(int photoId) async {
    final data = await _dao.getConnectionsForPhoto(photoId);
    return data.map(_toModel).toList();
  }

  /// 插入新关联
  ///
  /// 将业务模型转换为 Companion 对象后插入数据库，
  /// 返回带有数据库生成 ID 的新关联实例
  Future<Connection> insertConnection(Connection connection) async {
    final id = await _dao.insertConnection(_toCompanion(connection));
    return connection.copyWith(id: id);
  }

  /// 更新已有关联
  ///
  /// 如果关联的 id 为 null 则返回 false（无法更新未持久化的关联），
  /// 否则将业务模型转换为 Companion 对象后执行更新
  Future<bool> updateConnection(Connection connection) async {
    if (connection.id == null) return false;
    return _dao.updateConnection(_toCompanion(connection));
  }

  /// 根据 ID 删除关联
  ///
  /// [id] 关联主键
  /// 返回受影响的行数
  Future<int> deleteConnection(int id) => _dao.deleteConnection(id);

  /// 将 Drift 数据实体转换为业务模型
  Connection _toModel(ConnectionsTableData data) {
    return Connection(
      id: data.id,
      fromCardId: data.fromCardId,
      toCardId: data.toCardId,
      fromPhotoId: data.fromPhotoId,
      toPhotoId: data.toPhotoId,
      label: data.label,
      connectionType: ConnectionType.fromName(data.connectionType),
      createdAt: data.createdAt,
    );
  }

  /// 将业务模型转换为 Drift Companion 对象
  ConnectionsTableCompanion _toCompanion(Connection connection) {
    return ConnectionsTableCompanion(
      id: connection.id != null ? Value(connection.id!) : const Value.absent(),
      fromCardId: Value(connection.fromCardId),
      toCardId: Value(connection.toCardId),
      fromPhotoId: Value(connection.fromPhotoId),
      toPhotoId: Value(connection.toPhotoId),
      label: Value(connection.label),
      connectionType: Value(connection.connectionType.name),
      createdAt: Value(connection.createdAt),
    );
  }
}
