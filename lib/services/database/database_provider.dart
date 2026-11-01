/// 数据库提供者模块
///
/// 本文件使用 Riverpod 依赖注入框架为应用提供 [AppDatabase] 的单例实例。
/// 确保整个应用生命周期中只创建一个数据库连接，并在不再需要时正确释放资源。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// 应用数据库单例提供者
///
/// 通过 Riverpod 的 [Provider] 创建 [AppDatabase] 实例，保证：
/// - **单例模式**：整个应用共享同一个数据库实例，避免重复打开数据库文件
/// - **自动释放**：当 Provider 被销毁时（如应用退出），通过 [ref.onDispose]
///   自动调用 [db.close()] 关闭数据库连接，释放系统资源
///
/// 使用方式：
/// ```dart
/// final db = ref.watch(appDatabaseProvider);
/// ```
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  // 创建数据库实例（首次访问时触发懒加载连接）
  final db = AppDatabase();
  // 注册销毁回调：当 Provider 生命周期结束时关闭数据库连接
  ref.onDispose(() => db.close());
  return db;
});
