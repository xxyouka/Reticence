/// 线索卡片模型
///
/// 在侦探风格的线索墙应用中，[ClueCard] 是核心数据模型之一，
/// 代表墙面上的一张线索卡片。每张卡片包含线索名称、标签分类、
/// 详细描述，以及在墙面上的位置和旋转角度，用于模拟真实侦探
/// 在软木板上钉上线索卡片的场景。
library;

import 'package:equatable/equatable.dart';

/// 线索卡片
///
/// 继承 [Equatable] 以实现基于值的相等性比较，当两张卡片的
/// 所有字段都相同时即视为相等。这在状态管理（如 Bloc/Provider）
/// 中非常重要，可以避免不必要的 UI 重建。
///
/// 卡片在墙面上可以自由拖拽和旋转，通过 [x]、[y]、[rotation]
/// 字段记录其空间状态。卡片之间可以通过 [Connection] 模型建立关联。
class ClueCard extends Equatable {
  /// 卡片在数据库中的唯一标识符
  ///
  /// 在新建卡片尚未持久化到数据库时为 `null`，插入数据库后由
  /// 自增主键赋值。因此该字段是可空的。
  final int? id;

  /// 线索名称（必填）
  ///
  /// 卡片上显示的标题文字，例如"嫌疑人A"、"案发现场"等，
  /// 是卡片的唯一必填字段。
  final String name;

  /// 标签列表
  ///
  /// 用于对线索进行分类和筛选，例如 ["嫌疑人", "关键证据"]。
  /// 默认为空列表。标签可用于在墙面上按类别高亮或过滤卡片。
  final List<String> tags;

  /// 线索详细描述
  ///
  /// 对线索的补充说明，例如发现时间、关键细节等。
  /// 可以为 `null`，表示用户尚未填写描述。
  /// 如需在 [copyWith] 中将描述清空为 `null`，需使用 [clearDescription] 参数。
  final String? description;

  /// 卡片在墙面上的 X 坐标位置
  ///
  /// 用于在画布上定位卡片的水平位置，默认为 0（左上角）。
  final double x;

  /// 卡片在墙面上的 Y 坐标位置
  ///
  /// 用于在画布上定位卡片的垂直位置，默认为 0（左上角）。
  final double y;

  /// 卡片的旋转角度（弧度）
  ///
  /// 用于模拟真实线索墙上卡片随意钉放的效果，默认为 0（无旋转）。
  final double rotation;

  /// 卡片宽度
  ///
  /// 卡片在墙面上的逻辑宽度（像素），默认为 160。
  final double width;

  /// 卡片高度
  ///
  /// 卡片在墙面上的逻辑高度（像素），默认为 90。
  final double height;

  /// 卡片创建时间
  ///
  /// 如果构造时未传入，则默认使用当前时间。
  final DateTime createdAt;

  /// 卡片最后更新时间
  ///
  /// 如果构造时未传入，则默认使用当前时间。
  /// 在卡片字段发生变更时应更新此字段。
  final DateTime updatedAt;

  /// 创建一张线索卡片
  ///
  /// [name] 为必填参数，其余参数均有默认值。
  /// [createdAt] 和 [updatedAt] 如果未传入，会自动设置为当前时间。
  ClueCard({
    this.id,
    required this.name,
    this.tags = const [],
    this.description,
    this.x = 0,
    this.y = 0,
    this.rotation = 0,
    this.width = 160.0,
    this.height = 90.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 用于 [Equatable] 值比较的属性列表
  ///
  /// 当所有列出的属性都相等时，两个 [ClueCard] 实例被视为相等。
  /// 这确保了状态管理框架能正确判断状态是否发生变化。
  @override
  List<Object?> get props => [
        id,
        name,
        tags,
        description,
        x,
        y,
        rotation,
        width,
        height,
        createdAt,
        updatedAt
      ];

  /// 基于当前卡片创建一个副本，可选择性地修改部分字段
  ///
  /// 未传入的参数将保留原值。对于可空字段 [description]，存在一个
  /// Dart 语言层面的设计问题：**Dart 无法区分"传入 null"和"未传入参数"**，
  /// 因为 `description ?? this.description` 在传入 `null` 时会回退到原值，
  /// 导致无法通过 [copyWith] 将描述清空为 `null`。
  ///
  /// 为解决此问题，引入 [clearDescription] 布尔参数：
  /// - 当 [clearDescription] 为 `true` 时，无论 [description] 传入什么值，
  ///   描述都会被设置为 `null`。
  /// - 当 [clearDescription] 为 `false`（默认）时，行为与普通可选参数一致：
  ///   传入新值则更新，不传则保留原值。
  ///
  /// 示例：
  /// ```dart
  /// // 修改名称，保留描述
  /// card.copyWith(name: '新名称');
  ///
  /// // 清空描述
  /// card.copyWith(clearDescription: true);
  /// ```
  ClueCard copyWith({
    int? id,
    String? name,
    List<String>? tags,
    String? description,
    bool clearDescription = false, // 为 true 时将 description 强制设为 null
    double? x,
    double? y,
    double? rotation,
    double? width,
    double? height,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClueCard(
      id: id ?? this.id,
      name: name ?? this.name,
      tags: tags ?? this.tags,
      description: clearDescription ? null : (description ?? this.description),
      x: x ?? this.x,
      y: y ?? this.y,
      rotation: rotation ?? this.rotation,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
