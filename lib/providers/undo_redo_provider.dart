/// 撤销/重做 Provider 模块
///
/// 本文件实现了线索墙的撤销/重做功能，采用命令模式（Command Pattern）。
/// 核心设计：
/// - 每个可撤销操作封装为 [UndoableCommand]，包含执行和撤销逻辑
/// - [UndoRedoNotifier] 维护撤销栈和重做栈，控制操作历史
/// - 支持最大历史记录数限制，避免内存无限增长
/// - 通过快捷键（Ctrl+Z / Ctrl+Y）或手势触发撤销/重做
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 可撤销命令接口
///
/// 每个用户操作（添加卡片、删除卡片、移动卡片等）
/// 都封装为一个实现此接口的命令对象。
abstract class UndoableCommand {
  /// 命令的描述，用于调试和 UI 提示
  String get description;

  /// 执行命令（已在外部执行时可为空操作）
  Future<void> execute();

  /// 撤销命令，恢复到执行前的状态
  Future<void> undo();
}

/// 撤销/重做状态
///
/// 包含当前的撤销栈和重做栈，以及是否可以撤销/重做的状态。
class UndoRedoState {
  final List<UndoableCommand> undoStack;
  final List<UndoableCommand> redoStack;
  final int maxHistory;

  const UndoRedoState({
    this.undoStack = const [],
    this.redoStack = const [],
    this.maxHistory = 50,
  });

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  UndoRedoState copyWith({
    List<UndoableCommand>? undoStack,
    List<UndoableCommand>? redoStack,
  }) {
    return UndoRedoState(
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      maxHistory: maxHistory,
    );
  }
}

/// 撤销/重做通知器
///
/// 管理撤销栈和重做栈，提供以下操作：
/// - [executeCommand]：执行新命令并加入撤销栈
/// - [undo]：撤销最近的操作
/// - [redo]：重做最近撤销的操作
/// - [clear]：清空所有历史记录
class UndoRedoNotifier extends Notifier<UndoRedoState> {
  @override
  UndoRedoState build() {
    return const UndoRedoState();
  }

  /// 执行新命令
  ///
  /// 执行命令后将其压入撤销栈，并清空重做栈
  /// （因为执行新操作后，之前的重做历史不再有效）。
  Future<void> executeCommand(UndoableCommand command) async {
    await command.execute();

    final newUndoStack = [...state.undoStack, command];

    // 限制历史记录数量
    if (newUndoStack.length > state.maxHistory) {
      newUndoStack.removeAt(0);
    }

    state = state.copyWith(
      undoStack: newUndoStack,
      redoStack: [], // 执行新命令后清空重做栈
    );
  }

  /// 撤销最近的操作
  ///
  /// 从撤销栈弹出最近的命令，执行其撤销逻辑，
  /// 然后将该命令压入重做栈。
  Future<void> undo() async {
    if (!state.canUndo) return;

    final command = state.undoStack.last;
    final newUndoStack = [...state.undoStack]..removeLast();

    await command.undo();

    state = state.copyWith(
      undoStack: newUndoStack,
      redoStack: [...state.redoStack, command],
    );
  }

  /// 重做最近撤销的操作
  ///
  /// 从重做栈弹出最近的命令，重新执行该命令，
  /// 然后将该命令压回撤销栈。
  Future<void> redo() async {
    if (!state.canRedo) return;

    final command = state.redoStack.last;
    final newRedoStack = [...state.redoStack]..removeLast();

    await command.execute();

    state = state.copyWith(
      undoStack: [...state.undoStack, command],
      redoStack: newRedoStack,
    );
  }

  /// 清空所有历史记录
  void clear() {
    state = const UndoRedoState();
  }
}

/// 撤销/重做 Provider
final undoRedoProvider =
    NotifierProvider<UndoRedoNotifier, UndoRedoState>(UndoRedoNotifier.new);
