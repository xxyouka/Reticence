/// 数据库核心模块
///
/// 本文件定义了 Reticence 应用的主数据库类 [AppDatabase]，基于 Drift ORM 构建。
/// 负责以下核心职责：
/// - 声明数据库 Schema 版本及包含的表和 DAO
/// - 管理数据库迁移策略（版本升级时的表结构变更）
/// - 提供懒加载数据库连接（延迟初始化，后台线程打开数据库文件）
///
/// 数据库文件存储路径：应用文档目录/reticence.db
library;

import 'dart:developer';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';
import 'daos/card_dao.dart';
import 'daos/connection_dao.dart';
import 'daos/photo_dao.dart';

/// Drift 代码生成标记，生成文件为 app_database.g.dart
part 'app_database.g.dart';

/// Reticence 应用主数据库类
///
/// 继承自 Drift 代码生成的 _$AppDatabase，注册了三张数据表
/// 和三个 DAO（数据访问对象）。
///
/// Schema 版本历史：
/// - v1-v2：初始版本，仅包含 CardsTable 和 ConnectionsTable
/// - v3：基础稳定版
/// - v4：新增 CardsTable.cardType 和 ConnectionsTable.connectionType 列
/// - v5：新增 PhotosTable 照片附件表
@DriftDatabase(
    tables: [CardsTable, ConnectionsTable, PhotosTable],
    daos: [CardDao, ConnectionDao, PhotoDao])
class AppDatabase extends _$AppDatabase {
  /// 默认构造函数，使用懒加载连接方式打开数据库
  AppDatabase() : super(_openConnection());

  /// 测试用构造函数，允许注入自定义的查询执行器（如内存数据库）
  AppDatabase.forTesting(super.executor);

  /// 当前数据库 Schema 版本号
  // 每次表结构变更时必须递增此值，并同步更新迁移策略
  @override
  int get schemaVersion => 10;

  /// 检查指定表中是否存在指定列
  ///
  /// 通过 SQLite 的 PRAGMA table_info 命令查询表结构信息，
  /// 用于迁移时判断某列是否已经存在，避免重复添加导致报错。
  ///
  /// [tableName] 表名
  /// [columnName] 列名
  /// 返回 true 表示列已存在，false 表示不存在或查询出错
  Future<bool> _columnExists(String tableName, String columnName) async {
    try {
      final result = await customSelect(
        'PRAGMA table_info($tableName)',
      ).get();
      return result.any((row) => row.data['name'] == columnName);
    } catch (e) {
      log('Column check failed: $tableName.$columnName — $e', name: 'AppDatabase');
      return false;
    }
  }

  /// 数据库迁移策略
  ///
  /// 定义数据库创建和版本升级时的行为：
  ///
  /// **onCreate**：首次创建数据库时，执行 createAll 创建所有表。
  ///
  /// **onUpgrade**：版本升级时的增量迁移逻辑：
  /// - v3 → v4：为 CardsTable 添加 cardType 列（默认 'person'），
  ///   为 ConnectionsTable 添加 connectionType 列（默认 'neutral'）。
  ///   迁移前先检查列是否已存在，防止重复执行导致异常。
  /// - v4 → v5：创建 PhotosTable 照片附件表。
  ///
  /// 注意：迁移采用渐进式策略（if from < N），确保跨多个版本升级时
  /// 每一步迁移都能正确执行。例如从 v3 直接升级到 v5 时，
  /// v4 的迁移和 v5 的迁移会依次执行。
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v3 → v4：新增 cardType 和 connectionType 列
          if (from < 4) {
            // 检查 cards_table 是否已有 card_type 列，避免重复添加
            final cardsExists = await _columnExists('cards_table', 'card_type');
            if (!cardsExists) {
              await m.addColumn(cardsTable, cardsTable.cardType);
            }
            // 检查 connections_table 是否已有 connection_type 列，避免重复添加
            final connExists =
                await _columnExists('connections_table', 'connection_type');
            if (!connExists) {
              await m.addColumn(
                  connectionsTable, connectionsTable.connectionType);
            }
          }
          // v4 → v5：新增 PhotosTable 照片附件表
          if (from < 5) {
            await m.createTable(photosTable);
          }
          // v5 → v6：为卡片和照片添加缩放比例列
          if (from < 6) {
            final cardScaleExists = await _columnExists('cards_table', 'scale');
            if (!cardScaleExists) {
              await customStatement(
                  'ALTER TABLE cards_table ADD COLUMN scale REAL NOT NULL DEFAULT 1.0');
            }
            final photoScaleExists =
                await _columnExists('photos_table', 'scale');
            if (!photoScaleExists) {
              await customStatement(
                  'ALTER TABLE photos_table ADD COLUMN scale REAL NOT NULL DEFAULT 1.0');
            }
          }
          // v6 → v7：重建 connections_table，支持照片端点连接
          // fromCardId/toCardId 改为 nullable，新增 fromPhotoId/toPhotoId
          if (from < 7) {
            await customStatement('''
              CREATE TABLE connections_table_new (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                from_card_id INTEGER REFERENCES cards_table(id) ON DELETE CASCADE,
                to_card_id INTEGER REFERENCES cards_table(id) ON DELETE CASCADE,
                from_photo_id INTEGER REFERENCES photos_table(id) ON DELETE CASCADE,
                to_photo_id INTEGER REFERENCES photos_table(id) ON DELETE CASCADE,
                label TEXT,
                connection_type TEXT NOT NULL DEFAULT 'neutral',
                created_at INTEGER NOT NULL
              )
            ''');
            await customStatement('''
              INSERT INTO connections_table_new (id, from_card_id, to_card_id, label, connection_type, created_at)
                SELECT id, from_card_id, to_card_id, label, connection_type, created_at FROM connections_table
            ''');
            await customStatement('DROP TABLE connections_table');
            await customStatement(
                'ALTER TABLE connections_table_new RENAME TO connections_table');
            // 重建索引
            await customStatement(
                'CREATE INDEX idx_connections_from_card ON connections_table (from_card_id)');
            await customStatement(
                'CREATE INDEX idx_connections_to_card ON connections_table (to_card_id)');
            await customStatement(
                'CREATE INDEX idx_connections_from_photo ON connections_table (from_photo_id)');
            await customStatement(
                'CREATE INDEX idx_connections_to_photo ON connections_table (to_photo_id)');
          }
          // v7 → v8：为照片添加风格列
          if (from < 8) {
            final photoStyleExists =
                await _columnExists('photos_table', 'photo_style');
            if (!photoStyleExists) {
              await m.addColumn(photosTable, photosTable.photoStyle);
            }
          }
          // v8 → v9：scale → width + height
          if (from < 9) {
            // 卡片表：添加 width/height，用 scale * 默认值迁移旧数据
            final cardWidthExists = await _columnExists('cards_table', 'width');
            if (!cardWidthExists) {
              await m.addColumn(cardsTable, cardsTable.width);
            }
            final cardHeightExists =
                await _columnExists('cards_table', 'height');
            if (!cardHeightExists) {
              await m.addColumn(cardsTable, cardsTable.height);
            }
            // 迁移旧 scale 数据到 width/height（scale 列保留但不再使用）
            // 注意：170.0/100.0 是 v8 之前的旧默认卡片尺寸，此处必须与旧数据一致
            final cardScaleExists = await _columnExists('cards_table', 'scale');
            if (cardScaleExists) {
              await customStatement(
                  'UPDATE cards_table SET width = scale * 170.0, height = scale * 100.0 WHERE scale != 1.0');
            }
            // 照片表：添加 width/height
            final photoWidthExists =
                await _columnExists('photos_table', 'width');
            if (!photoWidthExists) {
              await m.addColumn(photosTable, photosTable.width);
            }
            final photoHeightExists =
                await _columnExists('photos_table', 'height');
            if (!photoHeightExists) {
              await m.addColumn(photosTable, photosTable.height);
            }
            // 迁移旧 scale 数据到 width/height
            // 注意：140.0/180.0 是照片卡片的默认尺寸，此处必须与旧数据一致
            final photoScaleExists =
                await _columnExists('photos_table', 'scale');
            if (photoScaleExists) {
              await customStatement(
                  'UPDATE photos_table SET width = scale * 140.0, height = scale * 180.0 WHERE scale != 1.0');
            }
          }
          // v9 → v10：删除附属照片功能
          // 1. 删除所有附属照片记录（type != 0）
          // 2. 删除附属照片相关列和索引
          if (from < 10) {
            // 删除附属照片记录
            await customStatement(
                'DELETE FROM photos_table WHERE type != 0');
            // 重建照片表，移除 type、attachedToCardId、attachedOffsetX、attachedOffsetY 列
            await customStatement('''
              CREATE TABLE photos_table_new (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                image_path TEXT NOT NULL,
                caption TEXT,
                x REAL NOT NULL,
                y REAL NOT NULL,
                rotation REAL NOT NULL DEFAULT 0,
                width REAL NOT NULL DEFAULT 140.0,
                height REAL NOT NULL DEFAULT 180.0,
                photo_style INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              )
            ''');
            await customStatement('''
              INSERT INTO photos_table_new (id, image_path, caption, x, y, rotation, width, height, photo_style, created_at, updated_at)
                SELECT id, image_path, caption, x, y, rotation, width, height, photo_style, created_at, updated_at FROM photos_table
            ''');
            await customStatement('DROP TABLE photos_table');
            await customStatement(
                'ALTER TABLE photos_table_new RENAME TO photos_table');
          }
        },
      );
}

/// 创建懒加载数据库连接
///
/// 使用 [LazyDatabase] 延迟执行数据库文件的打开操作，直到首次查询时才真正初始化。
/// 数据库文件位于应用文档目录下，文件名为 'reticence.db'。
///
/// [NativeDatabase.createInBackground] 在后台隔离线程中执行数据库操作，
/// 避免阻塞 UI 线程，确保应用流畅运行。
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // 获取应用文档目录（iOS/Android 系统分配的沙箱目录）
    final dbFolder = await getApplicationDocumentsDirectory();
    // 拼接数据库文件完整路径
    final file = File(p.join(dbFolder.path, 'reticence.db'));
    // 在后台线程中打开 SQLite 数据库
    return NativeDatabase.createInBackground(file);
  });
}
