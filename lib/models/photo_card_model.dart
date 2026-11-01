/// 照片卡片模型
///
/// 在侦探风格的线索墙应用中，[PhotoCard] 用于表示墙面上的一张照片。
/// 与文字线索卡片（[ClueCard]）不同，照片卡片以图片为核心内容，
/// 模拟侦探在线索墙上钉上照片、现场截图等视觉证据的场景。
library;

import 'package:equatable/equatable.dart';

/// 照片风格枚举
///
/// 定义照片卡片的视觉外观风格，模拟不同年代的拍立得照片质感。
enum PhotoStyle {
  /// 经典拍立得 —— 白色边框，干净利落
  polaroid,

  /// 复古拍立得 —— 泛黄旧纸色边框，岁月质感
  vintage,
}

/// 照片卡片
///
/// 继承 [Equatable] 以实现基于值的相等性比较，当两张照片卡片的
/// 所有字段都相同时即视为相等。这在状态管理（如 Bloc/Provider）
/// 中非常重要，可以避免不必要的 UI 重建。
///
/// 照片卡片的核心是 [imagePath] 指向的图片文件。
class PhotoCard extends Equatable {
  /// 照片卡片在数据库中的唯一标识符
  ///
  /// 在新建卡片尚未持久化到数据库时为 `null`，插入数据库后由
  /// 自增主键赋值。因此该字段是可空的。
  final int? id;

  /// 图片文件路径（必填）
  ///
  /// 指向本地存储中的图片文件路径，用于在墙面上显示照片。
  /// 通常为应用沙盒目录下的文件路径。
  final String imagePath;

  /// 照片说明文字
  ///
  /// 对照片内容的简要描述，例如"案发现场入口"、"嫌疑人近照"等。
  /// 可以为 `null`，表示用户未添加说明。
  /// 如需在 [copyWith] 中将说明清空为 `null`，需使用 [clearCaption] 参数。
  final String? caption;

  /// 照片在墙面上的 X 坐标位置，默认为 0
  final double x;

  /// 照片在墙面上的 Y 坐标位置，默认为 0
  final double y;

  /// 照片的旋转角度（度）
  ///
  /// 用于模拟真实线索墙上照片随意钉放的效果，默认为 0（无旋转）。
  final double rotation;

  /// 照片宽度
  ///
  /// 照片卡片在墙面上的逻辑宽度（像素），默认为 140。
  final double width;

  /// 照片高度
  ///
  /// 照片卡片在墙面上的逻辑高度（像素），默认为 180。
  final double height;

  /// 照片风格
  ///
  /// 决定照片卡片的视觉外观，默认为 [PhotoStyle.polaroid]（经典拍立得）。
  final PhotoStyle photoStyle;

  /// 照片卡片创建时间
  ///
  /// 如果构造时未传入，则默认使用当前时间。
  final DateTime createdAt;

  /// 照片卡片最后更新时间
  ///
  /// 如果构造时未传入，则默认使用当前时间。
  /// 在卡片字段发生变更时应更新此字段。
  final DateTime updatedAt;

  /// 创建一张照片卡片
  ///
  /// [imagePath] 为必填参数，其余参数均有默认值。
  /// [createdAt] 和 [updatedAt] 如果未传入，会自动设置为当前时间。
  PhotoCard({
    this.id,
    required this.imagePath,
    this.caption,
    this.x = 0,
    this.y = 0,
    this.rotation = 0,
    this.width = 140.0,
    this.height = 180.0,
    this.photoStyle = PhotoStyle.polaroid,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 用于 [Equatable] 值比较的属性列表
  ///
  /// 当所有列出的属性都相等时，两个 [PhotoCard] 实例被视为相等。
  /// 这确保了状态管理框架能正确判断状态是否发生变化。
  @override
  List<Object?> get props => [
        id,
        imagePath,
        caption,
        x,
        y,
        rotation,
        width,
        height,
        photoStyle,
        createdAt,
        updatedAt,
      ];

  /// 基于当前照片卡片创建一个副本，可选择性地修改部分字段
  ///
  /// 未传入的参数将保留原值。对于可空字段 [caption]，
  /// 存在一个 Dart 语言层面的设计问题：**Dart 无法区分"传入 null"和"未传入参数"**，
  /// 因为 `caption ?? this.caption` 在传入 `null` 时会回退到原值，
  /// 导致无法通过 [copyWith] 将字段清空为 `null`。
  ///
  /// 为解决此问题，引入 [clearCaption] 布尔参数：
  /// - 当 [clearCaption] 为 `true` 时，无论 [caption] 传入什么值，
  ///   说明文字都会被设置为 `null`。
  /// - 当 [clearCaption] 为 `false`（默认）时，行为与普通可选参数一致：
  ///   传入新值则更新，不传则保留原值。
  PhotoCard copyWith({
    int? id,
    String? imagePath,
    String? caption,
    bool clearCaption = false,
    double? x,
    double? y,
    double? rotation,
    double? width,
    double? height,
    PhotoStyle? photoStyle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PhotoCard(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      caption: clearCaption ? null : (caption ?? this.caption),
      x: x ?? this.x,
      y: y ?? this.y,
      rotation: rotation ?? this.rotation,
      width: width ?? this.width,
      height: height ?? this.height,
      photoStyle: photoStyle ?? this.photoStyle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
