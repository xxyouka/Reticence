/// 数据库表定义模块
///
/// 本文件定义了 Reticence 应用中所有 Drift（原 Moor）ORM 的数据表结构。
/// 包含三张核心表：
/// - [CardsTable]：线索卡片表，存储人物/事件等核心实体
/// - [ConnectionsTable]：卡片关联表，记录卡片之间的关系
/// - [PhotosTable]：照片附件表，存储附加在卡片上的图片信息
///
/// 表之间通过外键建立引用关系，并配置了级联删除（CASCADE），
/// 确保删除卡片时自动清理关联的连接和照片数据。
library;

import 'package:drift/drift.dart';

/// 线索卡片表
///
/// 存储画布上的核心实体（人物、地点、事件等），每张卡片在画布上
/// 拥有独立的位置坐标和旋转角度，支持标签（tags）分类和文字描述。
class CardsTable extends Table {
  /// 主键，自增整数 ID
  IntColumn get id => integer().autoIncrement()();

  /// 卡片名称，必填文本
  TextColumn get name => text()();

  /// 标签列表，以 JSON 数组字符串形式存储（如 '["嫌疑人","目击者"]'）
  // 序列化/反序列化逻辑在 CardRepository 中处理
  TextColumn get tags => text()();

  /// 卡片描述，可选文本
  TextColumn get description => text().nullable()();

  /// 卡片类型，文本枚举，默认值 'person'
  // 取值范围：person / event / location 等
  // 在 v4 迁移中新增
  TextColumn get cardType => text().withDefault(const Constant('person'))();

  /// 卡片在画布上的 X 坐标
  RealColumn get x => real()();

  /// 卡片在画布上的 Y 坐标
  RealColumn get y => real()();

  /// 卡片旋转角度（弧度），默认 0
  RealColumn get rotation => real().withDefault(const Constant(0))();

  /// 卡片宽度，默认 160
  RealColumn get width => real().withDefault(const Constant(160.0))();

  /// 卡片高度，默认 90
  RealColumn get height => real().withDefault(const Constant(90.0))();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime()();
}

/// 卡片关联表
///
/// 记录两张卡片之间的有向连接关系（从 fromCardId 指向 toCardId），
/// 支持标签标注和连接类型分类（盟友/敌人/中立/自定义）。
///
/// 外键均引用 [CardsTable.id]，并设置级联删除（CASCADE）：
/// 当被引用的卡片被删除时，该卡片相关的所有连接记录将自动删除。
///
/// 索引：
/// - [idx_connections_from_card]：加速按起始卡片查询连接
/// - [idx_connections_to_card]：加速按目标卡片查询连接
@TableIndex(name: 'idx_connections_from_card', columns: {#fromCardId})
@TableIndex(name: 'idx_connections_to_card', columns: {#toCardId})
@TableIndex(name: 'idx_connections_from_photo', columns: {#fromPhotoId})
@TableIndex(name: 'idx_connections_to_photo', columns: {#toPhotoId})
class ConnectionsTable extends Table {
  /// 主键，自增整数 ID
  IntColumn get id => integer().autoIncrement()();

  /// 连接起始卡片 ID，外键引用 CardsTable.id，可选
  /// 与 fromPhotoId 互斥：恰好一个为非 null
  IntColumn get fromCardId => integer()
      .references(CardsTable, #id, onDelete: KeyAction.cascade)
      .nullable()();

  /// 连接目标卡片 ID，外键引用 CardsTable.id，可选
  /// 与 toPhotoId 互斥：恰好一个为非 null
  IntColumn get toCardId => integer()
      .references(CardsTable, #id, onDelete: KeyAction.cascade)
      .nullable()();

  /// 连接起始照片 ID，外键引用 PhotosTable.id，可选
  /// 与 fromCardId 互斥：恰好一个为非 null
  IntColumn get fromPhotoId => integer()
      .references(PhotosTable, #id, onDelete: KeyAction.cascade)
      .nullable()();

  /// 连接目标照片 ID，外键引用 PhotosTable.id，可选
  /// 与 toCardId 互斥：恰好一个为非 null
  IntColumn get toPhotoId => integer()
      .references(PhotosTable, #id, onDelete: KeyAction.cascade)
      .nullable()();

  /// 连接标签，可选文本（如 "同事"、"仇人" 等）
  TextColumn get label => text().nullable()();

  /// 连接类型，文本枚举，默认值 'neutral'
  // 取值范围：neutral / ally / enemy / custom
  // 在 v4 迁移中新增
  TextColumn get connectionType =>
      text().withDefault(const Constant('neutral'))();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();
}

/// 照片附件表
///
/// 存储附加到卡片上的图片信息，每张照片在画布上有独立的位置和旋转角度。
/// 照片可以独立存在（不依附任何卡片），也可以附加到某张卡片上，
/// 照片表
///
/// 存储线索墙上的照片卡片数据。
class PhotosTable extends Table {
  /// 主键，自增整数 ID
  IntColumn get id => integer().autoIncrement()();

  /// 图片文件路径，必填文本
  TextColumn get imagePath => text()();

  /// 照片说明文字，可选文本
  TextColumn get caption => text().nullable()();

  /// 照片在画布上的 X 坐标
  RealColumn get x => real()();

  /// 照片在画布上的 Y 坐标
  RealColumn get y => real()();

  /// 照片旋转角度（弧度），默认 0
  RealColumn get rotation => real().withDefault(const Constant(0))();

  /// 照片宽度，默认 140
  RealColumn get width => real().withDefault(const Constant(140.0))();

  /// 照片高度，默认 180
  RealColumn get height => real().withDefault(const Constant(180.0))();

  /// 照片风格，以枚举索引（int）存储
  // 对应 PhotoStyle 枚举的 index 值
  // 0 = polaroid（经典拍立得），1 = vintage（复古拍立得）
  IntColumn get photoStyle => integer().withDefault(const Constant(0))();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 最后更新时间
  DateTimeColumn get updatedAt => dateTime()();
}
