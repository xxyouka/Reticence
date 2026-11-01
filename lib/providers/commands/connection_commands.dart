/// 连线相关撤销命令
///
/// 实现连线的添加、删除等操作的撤销/重做逻辑。
library;

import '../../models/connection_model.dart';
import '../connection_provider.dart';
import '../undo_redo_provider.dart';

/// 添加连线命令
///
/// 撤销时删除该连线，重做时重新添加。
class AddConnectionCommand extends UndoableCommand {
  final ConnectionListNotifier connectionNotifier;
  final Connection connection;
  Connection? _createdConnection;

  /// 执行后实际创建的连线（含数据库生成的 id）
  Connection? get createdConnection => _createdConnection;

  AddConnectionCommand(this.connectionNotifier, this.connection);

  @override
  String get description => '添加连线';

  @override
  Future<void> execute() async {
    _createdConnection = await connectionNotifier.addConnection(connection);
  }

  @override
  Future<void> undo() async {
    if (_createdConnection?.id != null) {
      await connectionNotifier.deleteConnection(_createdConnection!.id!);
    }
  }
}

/// 删除连线命令
///
/// 撤销时重新添加该连线，重做时删除。
class DeleteConnectionCommand extends UndoableCommand {
  final ConnectionListNotifier connectionNotifier;
  final Connection connection;

  DeleteConnectionCommand(this.connectionNotifier, this.connection);

  @override
  String get description => '删除连线 "${connection.label ?? '无标签'}"';

  @override
  Future<void> execute() async {
    if (connection.id != null) {
      await connectionNotifier.deleteConnection(connection.id!);
    }
  }

  @override
  Future<void> undo() async {
    await connectionNotifier.addConnection(connection);
  }
}

/// 更新连线命令
///
/// 撤销时恢复旧连线数据，重做时应用新连线数据。
class UpdateConnectionCommand extends UndoableCommand {
  final ConnectionListNotifier connectionNotifier;
  final Connection oldConnection;
  final Connection newConnection;

  UpdateConnectionCommand(this.connectionNotifier, this.oldConnection, this.newConnection);

  @override
  String get description => '更新连线';

  @override
  Future<void> execute() async {
    await connectionNotifier.updateConnection(newConnection);
  }

  @override
  Future<void> undo() async {
    await connectionNotifier.updateConnection(oldConnection);
  }
}
