/// 卡片仓库模块
///
/// 本文件实现了 [CardRepository] 类，采用 Repository 模式封装卡片数据的持久化操作。
/// 作为业务层（Model）与数据访问层（DAO）之间的桥梁，负责：
/// - 将 Drift 生成的数据实体（CardsTableData）转换为业务模型（ClueCard）
/// - 将业务模型（ClueCard）转换为 Drift 的 Companion 对象用于写入操作
/// - 处理 tags 字段的 JSON 序列化/反序列化（数据库存储为 JSON 字符串，业务层使用 `List<String>`）
library;

import 'dart:convert';
import 'dart:developer';

import 'package:drift/drift.dart';

import '../../models/card_model.dart';
import '../database/app_database.dart';
import '../database/daos/card_dao.dart';

/// 卡片数据仓库
///
/// 封装 [CardDao] 的数据访问操作，提供面向业务层的增删改查接口。
/// 核心职责是处理数据层实体与业务模型之间的转换，特别是 tags 字段的
/// JSON 序列化/反序列化逻辑。
class CardRepository {
  /// 卡片数据访问对象
  final CardDao _dao;

  CardRepository(this._dao);

  /// 获取所有卡片
  ///
  /// 返回业务模型 [ClueCard] 列表，将数据库实体逐个转换为业务模型
  Future<List<ClueCard>> getAllCards() async {
    final data = await _dao.getAllCards();
    return data.map(_toModel).toList();
  }

  /// 根据 ID 获取单张卡片
  ///
  /// [id] 卡片主键
  /// 返回对应的业务模型 [ClueCard]
  Future<ClueCard> getCardById(int id) async {
    final data = await _dao.getCardById(id);
    return _toModel(data);
  }

  /// 插入新卡片
  ///
  /// 将业务模型转换为 Companion 对象后插入数据库，
  /// 返回带有数据库生成 ID 的新卡片实例
  Future<ClueCard> insertCard(ClueCard card) async {
    final id = await _dao.insertCard(_toCompanion(card));
    return card.copyWith(id: id);
  }

  /// 更新已有卡片
  ///
  /// 如果卡片的 id 为 null 则返回 false（无法更新未持久化的卡片），
  /// 否则将业务模型转换为 Companion 对象后执行更新
  Future<bool> updateCard(ClueCard card) async {
    if (card.id == null) return false;
    return _dao.updateCard(_toCompanion(card.copyWith(updatedAt: DateTime.now())));
  }

  /// 根据 ID 删除卡片
  ///
  /// [id] 卡片主键
  /// 返回受影响的行数
  Future<int> deleteCard(int id) => _dao.deleteCard(id);

  /// 将 Drift 数据实体转换为业务模型
  ///
  /// 核心转换逻辑：
  /// - **tags 字段**：数据库中以 JSON 数组字符串存储（如 '["嫌疑人","目击者"]'），
  ///   使用 [jsonDecode] 反序列化为 `List<String>`。如果解析失败（如空字符串或格式错误），
  ///   降级返回空列表，保证应用不会因数据异常而崩溃
  /// - 其余字段直接映射，类型一致无需转换
  ClueCard _toModel(CardsTableData data) {
    List<String> tags;
    try {
      // 将 JSON 字符串解码为动态列表，再转换为 List<String>
      final List<dynamic> decoded = jsonDecode(data.tags);
      tags = List<String>.from(decoded);
    } catch (e) {
      // JSON 解析失败时降级为空列表，确保应用健壮性
      log('Failed to parse tags JSON: $e', name: 'CardRepository');
      tags = [];
    }
    return ClueCard(
      id: data.id,
      name: data.name,
      tags: tags,
      description: data.description,
      cardType: CardType.fromName(data.cardType),
      x: data.x,
      y: data.y,
      rotation: data.rotation,
      width: data.width,
      height: data.height,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// 将业务模型转换为 Drift Companion 对象
  ///
  /// Companion 对象用于 Drift 的插入和更新操作，支持部分字段缺席（Value.absent）。
  /// 核心转换逻辑：
  /// - **id 字段**：如果为 null 则使用 [Value.absent]，让数据库自动生成自增 ID；
  ///   如果不为 null 则使用 [Value] 包装，用于更新操作
  /// - **tags 字段**：将 `List<String>` 使用 [jsonEncode] 序列化为 JSON 字符串
  CardsTableCompanion _toCompanion(ClueCard card) {
    return CardsTableCompanion(
      id: card.id != null ? Value(card.id!) : const Value.absent(),
      name: Value(card.name),
      tags: Value(jsonEncode(card.tags)),
      description: Value(card.description),
      cardType: Value(card.cardType.name),
      x: Value(card.x),
      y: Value(card.y),
      rotation: Value(card.rotation),
      width: Value(card.width),
      height: Value(card.height),
      createdAt: Value(card.createdAt),
      updatedAt: Value(card.updatedAt),
    );
  }
}
