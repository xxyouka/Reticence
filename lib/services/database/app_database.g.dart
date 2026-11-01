// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CardsTableTable extends CardsTable
    with TableInfo<$CardsTableTable, CardsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cardTypeMeta =
      const VerificationMeta('cardType');
  @override
  late final GeneratedColumn<String> cardType = GeneratedColumn<String>(
      'card_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('person'));
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
      'x', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
      'y', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _rotationMeta =
      const VerificationMeta('rotation');
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
      'rotation', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
      'width', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(170.0));
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
      'height', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(100.0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        tags,
        description,
        cardType,
        x,
        y,
        rotation,
        width,
        height,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards_table';
  @override
  VerificationContext validateIntegrity(Insertable<CardsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    } else if (isInserting) {
      context.missing(_tagsMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('card_type')) {
      context.handle(_cardTypeMeta,
          cardType.isAcceptableOrUnknown(data['card_type']!, _cardTypeMeta));
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('rotation')) {
      context.handle(_rotationMeta,
          rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      cardType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_type'])!,
      x: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}x'])!,
      y: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}y'])!,
      rotation: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rotation'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}width'])!,
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CardsTableTable createAlias(String alias) {
    return $CardsTableTable(attachedDatabase, alias);
  }
}

class CardsTableData extends DataClass implements Insertable<CardsTableData> {
  /// 主键，自增整数 ID
  final int id;

  /// 卡片名称，必填文本
  final String name;

  /// 标签列表，以 JSON 数组字符串形式存储（如 '["嫌疑人","目击者"]'）
  final String tags;

  /// 卡片描述，可选文本
  final String? description;

  /// 卡片类型，文本枚举，默认值 'person'
  final String cardType;

  /// 卡片在画布上的 X 坐标
  final double x;

  /// 卡片在画布上的 Y 坐标
  final double y;

  /// 卡片旋转角度（弧度），默认 0
  final double rotation;

  /// 卡片宽度，默认 170
  final double width;

  /// 卡片高度，默认 100
  final double height;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;
  const CardsTableData(
      {required this.id,
      required this.name,
      required this.tags,
      this.description,
      required this.cardType,
      required this.x,
      required this.y,
      required this.rotation,
      required this.width,
      required this.height,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['card_type'] = Variable<String>(cardType);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['rotation'] = Variable<double>(rotation);
    map['width'] = Variable<double>(width);
    map['height'] = Variable<double>(height);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CardsTableCompanion toCompanion(bool nullToAbsent) {
    return CardsTableCompanion(
      id: Value(id),
      name: Value(name),
      tags: Value(tags),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      cardType: Value(cardType),
      x: Value(x),
      y: Value(y),
      rotation: Value(rotation),
      width: Value(width),
      height: Value(height),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CardsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardsTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      tags: serializer.fromJson<String>(json['tags']),
      description: serializer.fromJson<String?>(json['description']),
      cardType: serializer.fromJson<String>(json['cardType']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      rotation: serializer.fromJson<double>(json['rotation']),
      width: serializer.fromJson<double>(json['width']),
      height: serializer.fromJson<double>(json['height']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'tags': serializer.toJson<String>(tags),
      'description': serializer.toJson<String?>(description),
      'cardType': serializer.toJson<String>(cardType),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'rotation': serializer.toJson<double>(rotation),
      'width': serializer.toJson<double>(width),
      'height': serializer.toJson<double>(height),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CardsTableData copyWith(
          {int? id,
          String? name,
          String? tags,
          Value<String?> description = const Value.absent(),
          String? cardType,
          double? x,
          double? y,
          double? rotation,
          double? width,
          double? height,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CardsTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        tags: tags ?? this.tags,
        description: description.present ? description.value : this.description,
        cardType: cardType ?? this.cardType,
        x: x ?? this.x,
        y: y ?? this.y,
        rotation: rotation ?? this.rotation,
        width: width ?? this.width,
        height: height ?? this.height,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CardsTableData copyWithCompanion(CardsTableCompanion data) {
    return CardsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      tags: data.tags.present ? data.tags.value : this.tags,
      description:
          data.description.present ? data.description.value : this.description,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tags: $tags, ')
          ..write('description: $description, ')
          ..write('cardType: $cardType, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('rotation: $rotation, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, tags, description, cardType, x, y,
      rotation, width, height, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.tags == this.tags &&
          other.description == this.description &&
          other.cardType == this.cardType &&
          other.x == this.x &&
          other.y == this.y &&
          other.rotation == this.rotation &&
          other.width == this.width &&
          other.height == this.height &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CardsTableCompanion extends UpdateCompanion<CardsTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> tags;
  final Value<String?> description;
  final Value<String> cardType;
  final Value<double> x;
  final Value<double> y;
  final Value<double> rotation;
  final Value<double> width;
  final Value<double> height;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CardsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.tags = const Value.absent(),
    this.description = const Value.absent(),
    this.cardType = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.rotation = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CardsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String tags,
    this.description = const Value.absent(),
    this.cardType = const Value.absent(),
    required double x,
    required double y,
    this.rotation = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : name = Value(name),
        tags = Value(tags),
        x = Value(x),
        y = Value(y),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CardsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? tags,
    Expression<String>? description,
    Expression<String>? cardType,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? rotation,
    Expression<double>? width,
    Expression<double>? height,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (tags != null) 'tags': tags,
      if (description != null) 'description': description,
      if (cardType != null) 'card_type': cardType,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (rotation != null) 'rotation': rotation,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CardsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? tags,
      Value<String?>? description,
      Value<String>? cardType,
      Value<double>? x,
      Value<double>? y,
      Value<double>? rotation,
      Value<double>? width,
      Value<double>? height,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return CardsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      cardType: cardType ?? this.cardType,
      x: x ?? this.x,
      y: y ?? this.y,
      rotation: rotation ?? this.rotation,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(cardType.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tags: $tags, ')
          ..write('description: $description, ')
          ..write('cardType: $cardType, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('rotation: $rotation, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PhotosTableTable extends PhotosTable
    with TableInfo<$PhotosTableTable, PhotosTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _captionMeta =
      const VerificationMeta('caption');
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
      'caption', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
      'x', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
      'y', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _rotationMeta =
      const VerificationMeta('rotation');
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
      'rotation', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
      'width', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(140.0));
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
      'height', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(180.0));
  static const VerificationMeta _photoStyleMeta =
      const VerificationMeta('photoStyle');
  @override
  late final GeneratedColumn<int> photoStyle = GeneratedColumn<int>(
      'photo_style', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
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
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos_table';
  @override
  VerificationContext validateIntegrity(Insertable<PhotosTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(_captionMeta,
          caption.isAcceptableOrUnknown(data['caption']!, _captionMeta));
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('rotation')) {
      context.handle(_rotationMeta,
          rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('photo_style')) {
      context.handle(
          _photoStyleMeta,
          photoStyle.isAcceptableOrUnknown(
              data['photo_style']!, _photoStyleMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhotosTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotosTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path'])!,
      caption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}caption']),
      x: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}x'])!,
      y: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}y'])!,
      rotation: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rotation'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}width'])!,
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height'])!,
      photoStyle: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}photo_style'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PhotosTableTable createAlias(String alias) {
    return $PhotosTableTable(attachedDatabase, alias);
  }
}

class PhotosTableData extends DataClass implements Insertable<PhotosTableData> {
  /// 主键，自增整数 ID
  final int id;

  /// 图片文件路径，必填文本
  final String imagePath;

  /// 照片说明文字，可选文本
  final String? caption;

  /// 照片在画布上的 X 坐标
  final double x;

  /// 照片在画布上的 Y 坐标
  final double y;

  /// 照片旋转角度（弧度），默认 0
  final double rotation;

  /// 照片宽度，默认 140
  final double width;

  /// 照片高度，默认 180
  final double height;

  /// 照片风格，以枚举索引（int）存储
  final int photoStyle;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;
  const PhotosTableData(
      {required this.id,
      required this.imagePath,
      this.caption,
      required this.x,
      required this.y,
      required this.rotation,
      required this.width,
      required this.height,
      required this.photoStyle,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['image_path'] = Variable<String>(imagePath);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['rotation'] = Variable<double>(rotation);
    map['width'] = Variable<double>(width);
    map['height'] = Variable<double>(height);
    map['photo_style'] = Variable<int>(photoStyle);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PhotosTableCompanion toCompanion(bool nullToAbsent) {
    return PhotosTableCompanion(
      id: Value(id),
      imagePath: Value(imagePath),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      x: Value(x),
      y: Value(y),
      rotation: Value(rotation),
      width: Value(width),
      height: Value(height),
      photoStyle: Value(photoStyle),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PhotosTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotosTableData(
      id: serializer.fromJson<int>(json['id']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      caption: serializer.fromJson<String?>(json['caption']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      rotation: serializer.fromJson<double>(json['rotation']),
      width: serializer.fromJson<double>(json['width']),
      height: serializer.fromJson<double>(json['height']),
      photoStyle: serializer.fromJson<int>(json['photoStyle']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'imagePath': serializer.toJson<String>(imagePath),
      'caption': serializer.toJson<String?>(caption),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'rotation': serializer.toJson<double>(rotation),
      'width': serializer.toJson<double>(width),
      'height': serializer.toJson<double>(height),
      'photoStyle': serializer.toJson<int>(photoStyle),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PhotosTableData copyWith(
          {int? id,
          String? imagePath,
          Value<String?> caption = const Value.absent(),
          double? x,
          double? y,
          double? rotation,
          double? width,
          double? height,
          int? photoStyle,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      PhotosTableData(
        id: id ?? this.id,
        imagePath: imagePath ?? this.imagePath,
        caption: caption.present ? caption.value : this.caption,
        x: x ?? this.x,
        y: y ?? this.y,
        rotation: rotation ?? this.rotation,
        width: width ?? this.width,
        height: height ?? this.height,
        photoStyle: photoStyle ?? this.photoStyle,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PhotosTableData copyWithCompanion(PhotosTableCompanion data) {
    return PhotosTableData(
      id: data.id.present ? data.id.value : this.id,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      caption: data.caption.present ? data.caption.value : this.caption,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      photoStyle:
          data.photoStyle.present ? data.photoStyle.value : this.photoStyle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotosTableData(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('caption: $caption, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('rotation: $rotation, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('photoStyle: $photoStyle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, imagePath, caption, x, y, rotation, width,
      height, photoStyle, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotosTableData &&
          other.id == this.id &&
          other.imagePath == this.imagePath &&
          other.caption == this.caption &&
          other.x == this.x &&
          other.y == this.y &&
          other.rotation == this.rotation &&
          other.width == this.width &&
          other.height == this.height &&
          other.photoStyle == this.photoStyle &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PhotosTableCompanion extends UpdateCompanion<PhotosTableData> {
  final Value<int> id;
  final Value<String> imagePath;
  final Value<String?> caption;
  final Value<double> x;
  final Value<double> y;
  final Value<double> rotation;
  final Value<double> width;
  final Value<double> height;
  final Value<int> photoStyle;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PhotosTableCompanion({
    this.id = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.caption = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.rotation = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.photoStyle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PhotosTableCompanion.insert({
    this.id = const Value.absent(),
    required String imagePath,
    this.caption = const Value.absent(),
    required double x,
    required double y,
    this.rotation = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.photoStyle = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : imagePath = Value(imagePath),
        x = Value(x),
        y = Value(y),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PhotosTableData> custom({
    Expression<int>? id,
    Expression<String>? imagePath,
    Expression<String>? caption,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? rotation,
    Expression<double>? width,
    Expression<double>? height,
    Expression<int>? photoStyle,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imagePath != null) 'image_path': imagePath,
      if (caption != null) 'caption': caption,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (rotation != null) 'rotation': rotation,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (photoStyle != null) 'photo_style': photoStyle,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PhotosTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? imagePath,
      Value<String?>? caption,
      Value<double>? x,
      Value<double>? y,
      Value<double>? rotation,
      Value<double>? width,
      Value<double>? height,
      Value<int>? photoStyle,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return PhotosTableCompanion(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      caption: caption ?? this.caption,
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

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (photoStyle.present) {
      map['photo_style'] = Variable<int>(photoStyle.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosTableCompanion(')
          ..write('id: $id, ')
          ..write('imagePath: $imagePath, ')
          ..write('caption: $caption, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('rotation: $rotation, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('photoStyle: $photoStyle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ConnectionsTableTable extends ConnectionsTable
    with TableInfo<$ConnectionsTableTable, ConnectionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _fromCardIdMeta =
      const VerificationMeta('fromCardId');
  @override
  late final GeneratedColumn<int> fromCardId = GeneratedColumn<int>(
      'from_card_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES cards_table (id) ON DELETE CASCADE'));
  static const VerificationMeta _toCardIdMeta =
      const VerificationMeta('toCardId');
  @override
  late final GeneratedColumn<int> toCardId = GeneratedColumn<int>(
      'to_card_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES cards_table (id) ON DELETE CASCADE'));
  static const VerificationMeta _fromPhotoIdMeta =
      const VerificationMeta('fromPhotoId');
  @override
  late final GeneratedColumn<int> fromPhotoId = GeneratedColumn<int>(
      'from_photo_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES photos_table (id) ON DELETE CASCADE'));
  static const VerificationMeta _toPhotoIdMeta =
      const VerificationMeta('toPhotoId');
  @override
  late final GeneratedColumn<int> toPhotoId = GeneratedColumn<int>(
      'to_photo_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES photos_table (id) ON DELETE CASCADE'));
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _connectionTypeMeta =
      const VerificationMeta('connectionType');
  @override
  late final GeneratedColumn<String> connectionType = GeneratedColumn<String>(
      'connection_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('neutral'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fromCardId,
        toCardId,
        fromPhotoId,
        toPhotoId,
        label,
        connectionType,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connections_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<ConnectionsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('from_card_id')) {
      context.handle(
          _fromCardIdMeta,
          fromCardId.isAcceptableOrUnknown(
              data['from_card_id']!, _fromCardIdMeta));
    }
    if (data.containsKey('to_card_id')) {
      context.handle(_toCardIdMeta,
          toCardId.isAcceptableOrUnknown(data['to_card_id']!, _toCardIdMeta));
    }
    if (data.containsKey('from_photo_id')) {
      context.handle(
          _fromPhotoIdMeta,
          fromPhotoId.isAcceptableOrUnknown(
              data['from_photo_id']!, _fromPhotoIdMeta));
    }
    if (data.containsKey('to_photo_id')) {
      context.handle(
          _toPhotoIdMeta,
          toPhotoId.isAcceptableOrUnknown(
              data['to_photo_id']!, _toPhotoIdMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    }
    if (data.containsKey('connection_type')) {
      context.handle(
          _connectionTypeMeta,
          connectionType.isAcceptableOrUnknown(
              data['connection_type']!, _connectionTypeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      fromCardId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_card_id']),
      toCardId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_card_id']),
      fromPhotoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_photo_id']),
      toPhotoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_photo_id']),
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label']),
      connectionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}connection_type'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ConnectionsTableTable createAlias(String alias) {
    return $ConnectionsTableTable(attachedDatabase, alias);
  }
}

class ConnectionsTableData extends DataClass
    implements Insertable<ConnectionsTableData> {
  /// 主键，自增整数 ID
  final int id;

  /// 连接起始卡片 ID，外键引用 CardsTable.id，可选
  /// 与 fromPhotoId 互斥：恰好一个为非 null
  final int? fromCardId;

  /// 连接目标卡片 ID，外键引用 CardsTable.id，可选
  /// 与 toPhotoId 互斥：恰好一个为非 null
  final int? toCardId;

  /// 连接起始照片 ID，外键引用 PhotosTable.id，可选
  /// 与 fromCardId 互斥：恰好一个为非 null
  final int? fromPhotoId;

  /// 连接目标照片 ID，外键引用 PhotosTable.id，可选
  /// 与 toCardId 互斥：恰好一个为非 null
  final int? toPhotoId;

  /// 连接标签，可选文本（如 "同事"、"仇人" 等）
  final String? label;

  /// 连接类型，文本枚举，默认值 'neutral'
  final String connectionType;

  /// 创建时间
  final DateTime createdAt;
  const ConnectionsTableData(
      {required this.id,
      this.fromCardId,
      this.toCardId,
      this.fromPhotoId,
      this.toPhotoId,
      this.label,
      required this.connectionType,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || fromCardId != null) {
      map['from_card_id'] = Variable<int>(fromCardId);
    }
    if (!nullToAbsent || toCardId != null) {
      map['to_card_id'] = Variable<int>(toCardId);
    }
    if (!nullToAbsent || fromPhotoId != null) {
      map['from_photo_id'] = Variable<int>(fromPhotoId);
    }
    if (!nullToAbsent || toPhotoId != null) {
      map['to_photo_id'] = Variable<int>(toPhotoId);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['connection_type'] = Variable<String>(connectionType);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ConnectionsTableCompanion toCompanion(bool nullToAbsent) {
    return ConnectionsTableCompanion(
      id: Value(id),
      fromCardId: fromCardId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromCardId),
      toCardId: toCardId == null && nullToAbsent
          ? const Value.absent()
          : Value(toCardId),
      fromPhotoId: fromPhotoId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromPhotoId),
      toPhotoId: toPhotoId == null && nullToAbsent
          ? const Value.absent()
          : Value(toPhotoId),
      label:
          label == null && nullToAbsent ? const Value.absent() : Value(label),
      connectionType: Value(connectionType),
      createdAt: Value(createdAt),
    );
  }

  factory ConnectionsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionsTableData(
      id: serializer.fromJson<int>(json['id']),
      fromCardId: serializer.fromJson<int?>(json['fromCardId']),
      toCardId: serializer.fromJson<int?>(json['toCardId']),
      fromPhotoId: serializer.fromJson<int?>(json['fromPhotoId']),
      toPhotoId: serializer.fromJson<int?>(json['toPhotoId']),
      label: serializer.fromJson<String?>(json['label']),
      connectionType: serializer.fromJson<String>(json['connectionType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fromCardId': serializer.toJson<int?>(fromCardId),
      'toCardId': serializer.toJson<int?>(toCardId),
      'fromPhotoId': serializer.toJson<int?>(fromPhotoId),
      'toPhotoId': serializer.toJson<int?>(toPhotoId),
      'label': serializer.toJson<String?>(label),
      'connectionType': serializer.toJson<String>(connectionType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ConnectionsTableData copyWith(
          {int? id,
          Value<int?> fromCardId = const Value.absent(),
          Value<int?> toCardId = const Value.absent(),
          Value<int?> fromPhotoId = const Value.absent(),
          Value<int?> toPhotoId = const Value.absent(),
          Value<String?> label = const Value.absent(),
          String? connectionType,
          DateTime? createdAt}) =>
      ConnectionsTableData(
        id: id ?? this.id,
        fromCardId: fromCardId.present ? fromCardId.value : this.fromCardId,
        toCardId: toCardId.present ? toCardId.value : this.toCardId,
        fromPhotoId: fromPhotoId.present ? fromPhotoId.value : this.fromPhotoId,
        toPhotoId: toPhotoId.present ? toPhotoId.value : this.toPhotoId,
        label: label.present ? label.value : this.label,
        connectionType: connectionType ?? this.connectionType,
        createdAt: createdAt ?? this.createdAt,
      );
  ConnectionsTableData copyWithCompanion(ConnectionsTableCompanion data) {
    return ConnectionsTableData(
      id: data.id.present ? data.id.value : this.id,
      fromCardId:
          data.fromCardId.present ? data.fromCardId.value : this.fromCardId,
      toCardId: data.toCardId.present ? data.toCardId.value : this.toCardId,
      fromPhotoId:
          data.fromPhotoId.present ? data.fromPhotoId.value : this.fromPhotoId,
      toPhotoId: data.toPhotoId.present ? data.toPhotoId.value : this.toPhotoId,
      label: data.label.present ? data.label.value : this.label,
      connectionType: data.connectionType.present
          ? data.connectionType.value
          : this.connectionType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionsTableData(')
          ..write('id: $id, ')
          ..write('fromCardId: $fromCardId, ')
          ..write('toCardId: $toCardId, ')
          ..write('fromPhotoId: $fromPhotoId, ')
          ..write('toPhotoId: $toPhotoId, ')
          ..write('label: $label, ')
          ..write('connectionType: $connectionType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fromCardId, toCardId, fromPhotoId,
      toPhotoId, label, connectionType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionsTableData &&
          other.id == this.id &&
          other.fromCardId == this.fromCardId &&
          other.toCardId == this.toCardId &&
          other.fromPhotoId == this.fromPhotoId &&
          other.toPhotoId == this.toPhotoId &&
          other.label == this.label &&
          other.connectionType == this.connectionType &&
          other.createdAt == this.createdAt);
}

class ConnectionsTableCompanion extends UpdateCompanion<ConnectionsTableData> {
  final Value<int> id;
  final Value<int?> fromCardId;
  final Value<int?> toCardId;
  final Value<int?> fromPhotoId;
  final Value<int?> toPhotoId;
  final Value<String?> label;
  final Value<String> connectionType;
  final Value<DateTime> createdAt;
  const ConnectionsTableCompanion({
    this.id = const Value.absent(),
    this.fromCardId = const Value.absent(),
    this.toCardId = const Value.absent(),
    this.fromPhotoId = const Value.absent(),
    this.toPhotoId = const Value.absent(),
    this.label = const Value.absent(),
    this.connectionType = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ConnectionsTableCompanion.insert({
    this.id = const Value.absent(),
    this.fromCardId = const Value.absent(),
    this.toCardId = const Value.absent(),
    this.fromPhotoId = const Value.absent(),
    this.toPhotoId = const Value.absent(),
    this.label = const Value.absent(),
    this.connectionType = const Value.absent(),
    required DateTime createdAt,
  }) : createdAt = Value(createdAt);
  static Insertable<ConnectionsTableData> custom({
    Expression<int>? id,
    Expression<int>? fromCardId,
    Expression<int>? toCardId,
    Expression<int>? fromPhotoId,
    Expression<int>? toPhotoId,
    Expression<String>? label,
    Expression<String>? connectionType,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromCardId != null) 'from_card_id': fromCardId,
      if (toCardId != null) 'to_card_id': toCardId,
      if (fromPhotoId != null) 'from_photo_id': fromPhotoId,
      if (toPhotoId != null) 'to_photo_id': toPhotoId,
      if (label != null) 'label': label,
      if (connectionType != null) 'connection_type': connectionType,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ConnectionsTableCompanion copyWith(
      {Value<int>? id,
      Value<int?>? fromCardId,
      Value<int?>? toCardId,
      Value<int?>? fromPhotoId,
      Value<int?>? toPhotoId,
      Value<String?>? label,
      Value<String>? connectionType,
      Value<DateTime>? createdAt}) {
    return ConnectionsTableCompanion(
      id: id ?? this.id,
      fromCardId: fromCardId ?? this.fromCardId,
      toCardId: toCardId ?? this.toCardId,
      fromPhotoId: fromPhotoId ?? this.fromPhotoId,
      toPhotoId: toPhotoId ?? this.toPhotoId,
      label: label ?? this.label,
      connectionType: connectionType ?? this.connectionType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fromCardId.present) {
      map['from_card_id'] = Variable<int>(fromCardId.value);
    }
    if (toCardId.present) {
      map['to_card_id'] = Variable<int>(toCardId.value);
    }
    if (fromPhotoId.present) {
      map['from_photo_id'] = Variable<int>(fromPhotoId.value);
    }
    if (toPhotoId.present) {
      map['to_photo_id'] = Variable<int>(toPhotoId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (connectionType.present) {
      map['connection_type'] = Variable<String>(connectionType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionsTableCompanion(')
          ..write('id: $id, ')
          ..write('fromCardId: $fromCardId, ')
          ..write('toCardId: $toCardId, ')
          ..write('fromPhotoId: $fromPhotoId, ')
          ..write('toPhotoId: $toPhotoId, ')
          ..write('label: $label, ')
          ..write('connectionType: $connectionType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CardsTableTable cardsTable = $CardsTableTable(this);
  late final $PhotosTableTable photosTable = $PhotosTableTable(this);
  late final $ConnectionsTableTable connectionsTable =
      $ConnectionsTableTable(this);
  late final Index idxConnectionsFromCard = Index('idx_connections_from_card',
      'CREATE INDEX idx_connections_from_card ON connections_table (from_card_id)');
  late final Index idxConnectionsToCard = Index('idx_connections_to_card',
      'CREATE INDEX idx_connections_to_card ON connections_table (to_card_id)');
  late final Index idxConnectionsFromPhoto = Index('idx_connections_from_photo',
      'CREATE INDEX idx_connections_from_photo ON connections_table (from_photo_id)');
  late final Index idxConnectionsToPhoto = Index('idx_connections_to_photo',
      'CREATE INDEX idx_connections_to_photo ON connections_table (to_photo_id)');
  late final CardDao cardDao = CardDao(this as AppDatabase);
  late final ConnectionDao connectionDao = ConnectionDao(this as AppDatabase);
  late final PhotoDao photoDao = PhotoDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cardsTable,
        photosTable,
        connectionsTable,
        idxConnectionsFromCard,
        idxConnectionsToCard,
        idxConnectionsFromPhoto,
        idxConnectionsToPhoto
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('cards_table',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('connections_table', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('cards_table',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('connections_table', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('photos_table',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('connections_table', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('photos_table',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('connections_table', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$CardsTableTableCreateCompanionBuilder = CardsTableCompanion Function({
  Value<int> id,
  required String name,
  required String tags,
  Value<String?> description,
  Value<String> cardType,
  required double x,
  required double y,
  Value<double> rotation,
  Value<double> width,
  Value<double> height,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$CardsTableTableUpdateCompanionBuilder = CardsTableCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> tags,
  Value<String?> description,
  Value<String> cardType,
  Value<double> x,
  Value<double> y,
  Value<double> rotation,
  Value<double> width,
  Value<double> height,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$CardsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CardsTableTable> {
  $$CardsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardType => $composableBuilder(
      column: $table.cardType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get x => $composableBuilder(
      column: $table.x, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get y => $composableBuilder(
      column: $table.y, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rotation => $composableBuilder(
      column: $table.rotation, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CardsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTableTable> {
  $$CardsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardType => $composableBuilder(
      column: $table.cardType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get x => $composableBuilder(
      column: $table.x, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get y => $composableBuilder(
      column: $table.y, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rotation => $composableBuilder(
      column: $table.rotation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CardsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTableTable> {
  $$CardsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CardsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardsTableTable,
    CardsTableData,
    $$CardsTableTableFilterComposer,
    $$CardsTableTableOrderingComposer,
    $$CardsTableTableAnnotationComposer,
    $$CardsTableTableCreateCompanionBuilder,
    $$CardsTableTableUpdateCompanionBuilder,
    (
      CardsTableData,
      BaseReferences<_$AppDatabase, $CardsTableTable, CardsTableData>
    ),
    CardsTableData,
    PrefetchHooks Function()> {
  $$CardsTableTableTableManager(_$AppDatabase db, $CardsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> cardType = const Value.absent(),
            Value<double> x = const Value.absent(),
            Value<double> y = const Value.absent(),
            Value<double> rotation = const Value.absent(),
            Value<double> width = const Value.absent(),
            Value<double> height = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CardsTableCompanion(
            id: id,
            name: name,
            tags: tags,
            description: description,
            cardType: cardType,
            x: x,
            y: y,
            rotation: rotation,
            width: width,
            height: height,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String tags,
            Value<String?> description = const Value.absent(),
            Value<String> cardType = const Value.absent(),
            required double x,
            required double y,
            Value<double> rotation = const Value.absent(),
            Value<double> width = const Value.absent(),
            Value<double> height = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              CardsTableCompanion.insert(
            id: id,
            name: name,
            tags: tags,
            description: description,
            cardType: cardType,
            x: x,
            y: y,
            rotation: rotation,
            width: width,
            height: height,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CardsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CardsTableTable,
    CardsTableData,
    $$CardsTableTableFilterComposer,
    $$CardsTableTableOrderingComposer,
    $$CardsTableTableAnnotationComposer,
    $$CardsTableTableCreateCompanionBuilder,
    $$CardsTableTableUpdateCompanionBuilder,
    (
      CardsTableData,
      BaseReferences<_$AppDatabase, $CardsTableTable, CardsTableData>
    ),
    CardsTableData,
    PrefetchHooks Function()>;
typedef $$PhotosTableTableCreateCompanionBuilder = PhotosTableCompanion
    Function({
  Value<int> id,
  required String imagePath,
  Value<String?> caption,
  required double x,
  required double y,
  Value<double> rotation,
  Value<double> width,
  Value<double> height,
  Value<int> photoStyle,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$PhotosTableTableUpdateCompanionBuilder = PhotosTableCompanion
    Function({
  Value<int> id,
  Value<String> imagePath,
  Value<String?> caption,
  Value<double> x,
  Value<double> y,
  Value<double> rotation,
  Value<double> width,
  Value<double> height,
  Value<int> photoStyle,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$PhotosTableTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTableTable> {
  $$PhotosTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get x => $composableBuilder(
      column: $table.x, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get y => $composableBuilder(
      column: $table.y, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rotation => $composableBuilder(
      column: $table.rotation, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get photoStyle => $composableBuilder(
      column: $table.photoStyle, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PhotosTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTableTable> {
  $$PhotosTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get x => $composableBuilder(
      column: $table.x, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get y => $composableBuilder(
      column: $table.y, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rotation => $composableBuilder(
      column: $table.rotation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get photoStyle => $composableBuilder(
      column: $table.photoStyle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PhotosTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTableTable> {
  $$PhotosTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get photoStyle => $composableBuilder(
      column: $table.photoStyle, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PhotosTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PhotosTableTable,
    PhotosTableData,
    $$PhotosTableTableFilterComposer,
    $$PhotosTableTableOrderingComposer,
    $$PhotosTableTableAnnotationComposer,
    $$PhotosTableTableCreateCompanionBuilder,
    $$PhotosTableTableUpdateCompanionBuilder,
    (
      PhotosTableData,
      BaseReferences<_$AppDatabase, $PhotosTableTable, PhotosTableData>
    ),
    PhotosTableData,
    PrefetchHooks Function()> {
  $$PhotosTableTableTableManager(_$AppDatabase db, $PhotosTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> imagePath = const Value.absent(),
            Value<String?> caption = const Value.absent(),
            Value<double> x = const Value.absent(),
            Value<double> y = const Value.absent(),
            Value<double> rotation = const Value.absent(),
            Value<double> width = const Value.absent(),
            Value<double> height = const Value.absent(),
            Value<int> photoStyle = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PhotosTableCompanion(
            id: id,
            imagePath: imagePath,
            caption: caption,
            x: x,
            y: y,
            rotation: rotation,
            width: width,
            height: height,
            photoStyle: photoStyle,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String imagePath,
            Value<String?> caption = const Value.absent(),
            required double x,
            required double y,
            Value<double> rotation = const Value.absent(),
            Value<double> width = const Value.absent(),
            Value<double> height = const Value.absent(),
            Value<int> photoStyle = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              PhotosTableCompanion.insert(
            id: id,
            imagePath: imagePath,
            caption: caption,
            x: x,
            y: y,
            rotation: rotation,
            width: width,
            height: height,
            photoStyle: photoStyle,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PhotosTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PhotosTableTable,
    PhotosTableData,
    $$PhotosTableTableFilterComposer,
    $$PhotosTableTableOrderingComposer,
    $$PhotosTableTableAnnotationComposer,
    $$PhotosTableTableCreateCompanionBuilder,
    $$PhotosTableTableUpdateCompanionBuilder,
    (
      PhotosTableData,
      BaseReferences<_$AppDatabase, $PhotosTableTable, PhotosTableData>
    ),
    PhotosTableData,
    PrefetchHooks Function()>;
typedef $$ConnectionsTableTableCreateCompanionBuilder
    = ConnectionsTableCompanion Function({
  Value<int> id,
  Value<int?> fromCardId,
  Value<int?> toCardId,
  Value<int?> fromPhotoId,
  Value<int?> toPhotoId,
  Value<String?> label,
  Value<String> connectionType,
  required DateTime createdAt,
});
typedef $$ConnectionsTableTableUpdateCompanionBuilder
    = ConnectionsTableCompanion Function({
  Value<int> id,
  Value<int?> fromCardId,
  Value<int?> toCardId,
  Value<int?> fromPhotoId,
  Value<int?> toPhotoId,
  Value<String?> label,
  Value<String> connectionType,
  Value<DateTime> createdAt,
});

final class $$ConnectionsTableTableReferences extends BaseReferences<
    _$AppDatabase, $ConnectionsTableTable, ConnectionsTableData> {
  $$ConnectionsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CardsTableTable _fromCardIdTable(_$AppDatabase db) =>
      db.cardsTable.createAlias($_aliasNameGenerator(
          db.connectionsTable.fromCardId, db.cardsTable.id));

  $$CardsTableTableProcessedTableManager? get fromCardId {
    final $_column = $_itemColumn<int>('from_card_id');
    if ($_column == null) return null;
    final manager = $$CardsTableTableTableManager($_db, $_db.cardsTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromCardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CardsTableTable _toCardIdTable(_$AppDatabase db) =>
      db.cardsTable.createAlias(
          $_aliasNameGenerator(db.connectionsTable.toCardId, db.cardsTable.id));

  $$CardsTableTableProcessedTableManager? get toCardId {
    final $_column = $_itemColumn<int>('to_card_id');
    if ($_column == null) return null;
    final manager = $$CardsTableTableTableManager($_db, $_db.cardsTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toCardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PhotosTableTable _fromPhotoIdTable(_$AppDatabase db) =>
      db.photosTable.createAlias($_aliasNameGenerator(
          db.connectionsTable.fromPhotoId, db.photosTable.id));

  $$PhotosTableTableProcessedTableManager? get fromPhotoId {
    final $_column = $_itemColumn<int>('from_photo_id');
    if ($_column == null) return null;
    final manager = $$PhotosTableTableTableManager($_db, $_db.photosTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromPhotoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $PhotosTableTable _toPhotoIdTable(_$AppDatabase db) =>
      db.photosTable.createAlias($_aliasNameGenerator(
          db.connectionsTable.toPhotoId, db.photosTable.id));

  $$PhotosTableTableProcessedTableManager? get toPhotoId {
    final $_column = $_itemColumn<int>('to_photo_id');
    if ($_column == null) return null;
    final manager = $$PhotosTableTableTableManager($_db, $_db.photosTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toPhotoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ConnectionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectionsTableTable> {
  $$ConnectionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get connectionType => $composableBuilder(
      column: $table.connectionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CardsTableTableFilterComposer get fromCardId {
    final $$CardsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromCardId,
        referencedTable: $db.cardsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableTableFilterComposer(
              $db: $db,
              $table: $db.cardsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CardsTableTableFilterComposer get toCardId {
    final $$CardsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toCardId,
        referencedTable: $db.cardsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableTableFilterComposer(
              $db: $db,
              $table: $db.cardsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PhotosTableTableFilterComposer get fromPhotoId {
    final $$PhotosTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromPhotoId,
        referencedTable: $db.photosTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PhotosTableTableFilterComposer(
              $db: $db,
              $table: $db.photosTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PhotosTableTableFilterComposer get toPhotoId {
    final $$PhotosTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toPhotoId,
        referencedTable: $db.photosTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PhotosTableTableFilterComposer(
              $db: $db,
              $table: $db.photosTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ConnectionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectionsTableTable> {
  $$ConnectionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get connectionType => $composableBuilder(
      column: $table.connectionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CardsTableTableOrderingComposer get fromCardId {
    final $$CardsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromCardId,
        referencedTable: $db.cardsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableTableOrderingComposer(
              $db: $db,
              $table: $db.cardsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CardsTableTableOrderingComposer get toCardId {
    final $$CardsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toCardId,
        referencedTable: $db.cardsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableTableOrderingComposer(
              $db: $db,
              $table: $db.cardsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PhotosTableTableOrderingComposer get fromPhotoId {
    final $$PhotosTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromPhotoId,
        referencedTable: $db.photosTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PhotosTableTableOrderingComposer(
              $db: $db,
              $table: $db.photosTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PhotosTableTableOrderingComposer get toPhotoId {
    final $$PhotosTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toPhotoId,
        referencedTable: $db.photosTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PhotosTableTableOrderingComposer(
              $db: $db,
              $table: $db.photosTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ConnectionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectionsTableTable> {
  $$ConnectionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get connectionType => $composableBuilder(
      column: $table.connectionType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CardsTableTableAnnotationComposer get fromCardId {
    final $$CardsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromCardId,
        referencedTable: $db.cardsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.cardsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CardsTableTableAnnotationComposer get toCardId {
    final $$CardsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toCardId,
        referencedTable: $db.cardsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.cardsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PhotosTableTableAnnotationComposer get fromPhotoId {
    final $$PhotosTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.fromPhotoId,
        referencedTable: $db.photosTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PhotosTableTableAnnotationComposer(
              $db: $db,
              $table: $db.photosTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$PhotosTableTableAnnotationComposer get toPhotoId {
    final $$PhotosTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toPhotoId,
        referencedTable: $db.photosTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PhotosTableTableAnnotationComposer(
              $db: $db,
              $table: $db.photosTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ConnectionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConnectionsTableTable,
    ConnectionsTableData,
    $$ConnectionsTableTableFilterComposer,
    $$ConnectionsTableTableOrderingComposer,
    $$ConnectionsTableTableAnnotationComposer,
    $$ConnectionsTableTableCreateCompanionBuilder,
    $$ConnectionsTableTableUpdateCompanionBuilder,
    (ConnectionsTableData, $$ConnectionsTableTableReferences),
    ConnectionsTableData,
    PrefetchHooks Function(
        {bool fromCardId, bool toCardId, bool fromPhotoId, bool toPhotoId})> {
  $$ConnectionsTableTableTableManager(
      _$AppDatabase db, $ConnectionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> fromCardId = const Value.absent(),
            Value<int?> toCardId = const Value.absent(),
            Value<int?> fromPhotoId = const Value.absent(),
            Value<int?> toPhotoId = const Value.absent(),
            Value<String?> label = const Value.absent(),
            Value<String> connectionType = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ConnectionsTableCompanion(
            id: id,
            fromCardId: fromCardId,
            toCardId: toCardId,
            fromPhotoId: fromPhotoId,
            toPhotoId: toPhotoId,
            label: label,
            connectionType: connectionType,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> fromCardId = const Value.absent(),
            Value<int?> toCardId = const Value.absent(),
            Value<int?> fromPhotoId = const Value.absent(),
            Value<int?> toPhotoId = const Value.absent(),
            Value<String?> label = const Value.absent(),
            Value<String> connectionType = const Value.absent(),
            required DateTime createdAt,
          }) =>
              ConnectionsTableCompanion.insert(
            id: id,
            fromCardId: fromCardId,
            toCardId: toCardId,
            fromPhotoId: fromPhotoId,
            toPhotoId: toPhotoId,
            label: label,
            connectionType: connectionType,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ConnectionsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {fromCardId = false,
              toCardId = false,
              fromPhotoId = false,
              toPhotoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (fromCardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fromCardId,
                    referencedTable:
                        $$ConnectionsTableTableReferences._fromCardIdTable(db),
                    referencedColumn: $$ConnectionsTableTableReferences
                        ._fromCardIdTable(db)
                        .id,
                  ) as T;
                }
                if (toCardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.toCardId,
                    referencedTable:
                        $$ConnectionsTableTableReferences._toCardIdTable(db),
                    referencedColumn:
                        $$ConnectionsTableTableReferences._toCardIdTable(db).id,
                  ) as T;
                }
                if (fromPhotoId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.fromPhotoId,
                    referencedTable:
                        $$ConnectionsTableTableReferences._fromPhotoIdTable(db),
                    referencedColumn: $$ConnectionsTableTableReferences
                        ._fromPhotoIdTable(db)
                        .id,
                  ) as T;
                }
                if (toPhotoId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.toPhotoId,
                    referencedTable:
                        $$ConnectionsTableTableReferences._toPhotoIdTable(db),
                    referencedColumn: $$ConnectionsTableTableReferences
                        ._toPhotoIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ConnectionsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConnectionsTableTable,
    ConnectionsTableData,
    $$ConnectionsTableTableFilterComposer,
    $$ConnectionsTableTableOrderingComposer,
    $$ConnectionsTableTableAnnotationComposer,
    $$ConnectionsTableTableCreateCompanionBuilder,
    $$ConnectionsTableTableUpdateCompanionBuilder,
    (ConnectionsTableData, $$ConnectionsTableTableReferences),
    ConnectionsTableData,
    PrefetchHooks Function(
        {bool fromCardId, bool toCardId, bool fromPhotoId, bool toPhotoId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CardsTableTableTableManager get cardsTable =>
      $$CardsTableTableTableManager(_db, _db.cardsTable);
  $$PhotosTableTableTableManager get photosTable =>
      $$PhotosTableTableTableManager(_db, _db.photosTable);
  $$ConnectionsTableTableTableManager get connectionsTable =>
      $$ConnectionsTableTableTableManager(_db, _db.connectionsTable);
}
