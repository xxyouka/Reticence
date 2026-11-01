/// 线索关联模型
///
/// 在侦探风格的线索墙应用中，[Connection] 用于表示两个线索元素
/// （卡片或照片）之间的关联关系。就像真实侦探用红线将墙上的线索
/// 连接起来一样，本模型记录了连接的起止位置、关系类型和标签，
/// 帮助用户理清人物关系和事件脉络。
///
/// 连接的两端可以是卡片（card）或照片（photo），通过四个可空 ID 字段
/// 组合表达：card→card、card→photo、photo→card、photo→photo。
/// 每条连接恰好有两个端点，恰好两个 ID 字段为非 null。
library;

import 'package:equatable/equatable.dart';

/// 关联类型
///
/// 与数据库中的 `connection_type` 字段对应，用于区分中立、盟友、敌对
/// 和自定义关系。默认值为 [ConnectionType.neutral]。
enum ConnectionType {
  neutral('中立'),
  ally('盟友'),
  enemy('敌对'),
  custom('自定义');

  const ConnectionType(this.label);

  /// 中文显示名称
  final String label;

  /// 从数据库字符串解析类型，未知值回退为 [ConnectionType.neutral]
  static ConnectionType fromName(String? name) =>
      values.asNameMap()[name] ?? ConnectionType.neutral;
}

/// 线索关联
///
/// 继承 [Equatable] 以实现基于值的相等性比较，当两个关联的
/// 所有字段都相同时即视为相等。这在状态管理中非常重要，
/// 可以避免因引用不同但内容相同的对象而导致不必要的 UI 重建。
///
/// 每条关联连接两个线索元素，元素可以是卡片或照片：
/// - card→card：[fromCardId] + [toCardId]
/// - card→photo：[fromCardId] + [toPhotoId]
/// - photo→card：[fromPhotoId] + [toCardId]
/// - photo→photo：[fromPhotoId] + [toPhotoId]
///
/// 恰好两个端点 ID 为非 null，其余两个为 null。
class Connection extends Equatable {
  /// 关联在数据库中的唯一标识符
  ///
  /// 在新建关联尚未持久化到数据库时为 `null`，插入数据库后由
  /// 自增主键赋值。因此该字段是可空的。
  final int? id;

  /// 连接起始卡片的 ID（可选）
  ///
  /// 指向 [ClueCard.id]，表示关联的起点为一张卡片。
  /// 与 [fromPhotoId] 互斥：恰好一个为非 null。
  final int? fromCardId;

  /// 连接目标卡片的 ID（可选）
  ///
  /// 指向 [ClueCard.id]，表示关联的终点为一张卡片。
  /// 与 [toPhotoId] 互斥：恰好一个为非 null。
  final int? toCardId;

  /// 连接起始照片的 ID（可选）
  ///
  /// 指向 [PhotoCard.id]，表示关联的起点为一张照片。
  /// 与 [fromCardId] 互斥：恰好一个为非 null。
  final int? fromPhotoId;

  /// 连接目标照片的 ID（可选）
  ///
  /// 指向 [PhotoCard.id]，表示关联的终点为一张照片。
  /// 与 [toCardId] 互斥：恰好一个为非 null。
  final int? toPhotoId;

  /// 关联标签
  ///
  /// 对关联关系的文字说明，例如"同伙"、"仇人"、"上下级"等。
  /// 可以为 `null`，表示用户未添加标签。
  /// 如需在 [copyWith] 中将标签清空为 `null`，需使用 [clearLabel] 参数。
  final String? label;

  /// 关联类型
  final ConnectionType connectionType;

  /// 关联创建时间
  ///
  /// 如果构造时未传入，则默认使用当前时间。
  final DateTime createdAt;

  /// 创建一条线索关联
  ///
  /// 必须指定两个端点（恰好两个 ID 字段为非 null）。
  /// [createdAt] 如果未传入，会自动设置为当前时间。
  Connection({
    this.id,
    this.fromCardId,
    this.toCardId,
    this.fromPhotoId,
    this.toPhotoId,
    this.label,
    this.connectionType = ConnectionType.neutral,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    assert(_hasValidEndpoints, 'Connection 必须恰好有两个端点 ID 非 null');
    if (!_hasValidEndpoints) {
      throw ArgumentError('Connection 必须恰好有两个端点 ID 非 null');
    }
  }

  /// 是否恰好有两个端点 ID 非 null（连接的不变量）
  bool get _hasValidEndpoints {
    final count = [fromCardId, toCardId, fromPhotoId, toPhotoId]
        .where((id) => id != null)
        .length;
    return count == 2;
  }

  /// 起始端是否为卡片
  bool get isFromCard => fromCardId != null;

  /// 终点端是否为卡片
  bool get isToCard => toCardId != null;

  /// 是否为卡片到卡片的连接
  bool get isCardToCard => fromCardId != null && toCardId != null;

  /// 是否涉及照片（任一端为照片）
  bool get involvesPhoto => fromPhotoId != null || toPhotoId != null;

  /// 判断此连接是否连接了指定的两个端点（双向匹配）
  ///
  /// 端点可以是卡片或照片，通过非 null 的 ID 指定。
  /// 例如 `connectsEndpoints(fromCardId: 1, toCardId: 2)` 会匹配
  /// `fromCardId=1, toCardId=2` 或 `fromCardId=2, toCardId=1`。
  bool connectsEndpoints({
    int? fromCardId,
    int? fromPhotoId,
    int? toCardId,
    int? toPhotoId,
  }) {
    // 正向匹配：A→B
    final forward = _matchesEndpoint(this.fromCardId, fromCardId) &&
        _matchesEndpoint(this.fromPhotoId, fromPhotoId) &&
        _matchesEndpoint(this.toCardId, toCardId) &&
        _matchesEndpoint(this.toPhotoId, toPhotoId);
    // 反向匹配：B→A
    final reverse = _matchesEndpoint(this.fromCardId, toCardId) &&
        _matchesEndpoint(this.fromPhotoId, toPhotoId) &&
        _matchesEndpoint(this.toCardId, fromCardId) &&
        _matchesEndpoint(this.toPhotoId, fromPhotoId);
    return forward || reverse;
  }

  static bool _matchesEndpoint(int? actual, int? expected) {
    if (expected == null) return true; // 未指定则不参与匹配
    return actual == expected;
  }

  /// 用于 [Equatable] 值比较的属性列表
  ///
  /// 当所有列出的属性都相等时，两个 [Connection] 实例被视为相等。
  /// 这确保了状态管理框架能正确判断状态是否发生变化。
  @override
  List<Object?> get props => [
        id,
        fromCardId,
        toCardId,
        fromPhotoId,
        toPhotoId,
        label,
        connectionType,
        createdAt,
      ];

  /// 基于当前关联创建一个副本，可选择性地修改部分字段
  ///
  /// 未传入的参数将保留原值。对于可空字段，存在一个
  /// Dart 语言层面的设计问题：**Dart 无法区分"传入 null"和"未传入参数"**，
  /// 因为 `param ?? this.param` 在传入 `null` 时会回退到原值，
  /// 导致无法通过 [copyWith] 将字段清空为 `null`。
  ///
  /// 为解决此问题，引入 clearXxx 布尔参数：
  /// - 当 clearXxx 为 `true` 时，无论对应字段传入什么值，都会被设置为 `null`。
  /// - 当 clearXxx 为 `false`（默认）时，行为与普通可选参数一致。
  Connection copyWith({
    int? id,
    int? fromCardId,
    int? toCardId,
    int? fromPhotoId,
    int? toPhotoId,
    String? label,
    ConnectionType? connectionType,
    bool clearLabel = false,
    bool clearFromCardId = false,
    bool clearToCardId = false,
    bool clearFromPhotoId = false,
    bool clearToPhotoId = false,
    DateTime? createdAt,
  }) {
    return Connection(
      id: id ?? this.id,
      fromCardId: clearFromCardId ? null : (fromCardId ?? this.fromCardId),
      toCardId: clearToCardId ? null : (toCardId ?? this.toCardId),
      fromPhotoId: clearFromPhotoId ? null : (fromPhotoId ?? this.fromPhotoId),
      toPhotoId: clearToPhotoId ? null : (toPhotoId ?? this.toPhotoId),
      label: clearLabel ? null : (label ?? this.label),
      connectionType: connectionType ?? this.connectionType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
