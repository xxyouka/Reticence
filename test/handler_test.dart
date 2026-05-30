import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reticence/providers/handlers/drag_handler.dart';
import 'package:reticence/providers/handlers/connection_handler.dart';
import 'package:reticence/providers/handlers/photo_drag_handler.dart';
import 'package:reticence/providers/handlers/selection_manager.dart';
import 'package:reticence/providers/undo_redo_provider.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/connection_model.dart';
import 'package:reticence/models/photo_card_model.dart';

void main() {
  group('DragHandler', () {
    late DragHandler handler;

    setUp(() {
      handler = DragHandler();
    });

    test('initial state is not dragging', () {
      expect(handler.isDragging, isFalse);
      expect(handler.draggingCardId, isNull);
    });

    test('onDragStart sets dragging state', () {
      final card = ClueCard(id: 1, name: 'A', x: 50, y: 75);
      handler.onDragStart(1, const Offset(100, 200), card);
      expect(handler.isDragging, isTrue);
      expect(handler.draggingCardId, 1);
      expect(handler.dragStart, const Offset(100, 200));
      expect(handler.cardStartPos, const Offset(50, 75));
    });

    test('onDragUpdate returns clamped position', () {
      final card = ClueCard(id: 1, name: 'A', x: 100, y: 100);
      handler.onDragStart(1, const Offset(200, 200), card);
      final pos = handler.onDragUpdate(const Offset(250, 280), 1.0);
      expect(pos, isNotNull);
      expect(pos!.dx, greaterThanOrEqualTo(0));
      expect(pos.dy, greaterThanOrEqualTo(0));
    });

    test('onDragUpdate returns null when not dragging', () {
      final pos = handler.onDragUpdate(const Offset(250, 280), 1.0);
      expect(pos, isNull);
    });

    test('onDragEnd returns card id and clears state', () {
      final card = ClueCard(id: 1, name: 'A', x: 50, y: 75);
      handler.onDragStart(1, const Offset(100, 200), card);
      final id = handler.onDragEnd();
      expect(id, 1);
      expect(handler.isDragging, isFalse);
      expect(handler.draggingCardId, isNull);
    });
  });

  group('ConnectionHandler', () {
    late ConnectionHandler handler;

    setUp(() {
      handler = ConnectionHandler();
    });

    test('initial state is not connecting', () {
      expect(handler.isConnecting, isFalse);
      expect(handler.connectingFromCardId, isNull);
    });

    test('startConnecting sets connecting state', () {
      final card = ClueCard(id: 1, name: 'A', x: 100, y: 100);
      handler.startConnecting(1, card);
      expect(handler.isConnecting, isTrue);
      expect(handler.connectingFromCardId, 1);
    });

    test('endConnecting clears state', () {
      final card = ClueCard(id: 1, name: 'A', x: 100, y: 100);
      handler.startConnecting(1, card);
      handler.endConnecting();
      expect(handler.isConnecting, isFalse);
      expect(handler.connectingFromCardId, isNull);
    });

    test('finishConnecting returns null when no target nearby', () {
      final card1 = ClueCard(id: 1, name: 'A', x: 0, y: 0);
      final card2 = ClueCard(id: 2, name: 'B', x: 500, y: 500);
      handler.startConnecting(1, card1);
      handler.connectingCurrentPos = const Offset(250, 250);
      final result = handler.finishConnecting([card1, card2], [], 1.0);
      expect(result, isNull);
      expect(handler.isConnecting, isFalse);
    });

    test('pushpinPosition returns correct offset', () {
      final card = ClueCard(id: 1, name: 'A', x: 100, y: 200);
      final pos = handler.pushpinPosition(card);
      expect(pos.dx, greaterThan(100));
      expect(pos.dy, 222);
    });
  });

  group('PhotoDragHandler', () {
    late PhotoDragHandler handler;

    setUp(() {
      handler = PhotoDragHandler();
    });

    test('initial state is not dragging', () {
      expect(handler.isDragging, isFalse);
      expect(handler.draggingPhotoId, isNull);
      expect(handler.photoStartPos, Offset.zero);
    });

    test('onDragStart sets dragging state', () {
      final photo = PhotoCard(id: 1, imagePath: 'a.jpg', x: 50, y: 75);
      handler.onDragStart(1, const Offset(100, 200), photo);
      expect(handler.isDragging, isTrue);
      expect(handler.draggingPhotoId, 1);
      expect(handler.photoStartPos, const Offset(50, 75));
    });

    test('onDragUpdate returns new position', () {
      final photo = PhotoCard(id: 1, imagePath: 'a.jpg', x: 100, y: 100);
      handler.onDragStart(1, const Offset(200, 200), photo);
      final pos = handler.onDragUpdate(const Offset(250, 280), 1.0);
      expect(pos, isNotNull);
      expect(pos!.dx, 150);
      expect(pos.dy, 180);
    });

    test('onDragUpdate scales delta by canvas scale', () {
      final photo = PhotoCard(id: 1, imagePath: 'a.jpg', x: 100, y: 100);
      handler.onDragStart(1, const Offset(200, 200), photo);
      final pos = handler.onDragUpdate(const Offset(300, 300), 2.0);
      expect(pos, isNotNull);
      expect(pos!.dx, 150);
      expect(pos.dy, 150);
    });

    test('onDragUpdate returns null when not dragging', () {
      final pos = handler.onDragUpdate(const Offset(250, 280), 1.0);
      expect(pos, isNull);
    });

    test('onDragEnd returns photo id and clears state', () {
      final photo = PhotoCard(id: 1, imagePath: 'a.jpg', x: 50, y: 75);
      handler.onDragStart(1, const Offset(100, 200), photo);
      final id = handler.onDragEnd();
      expect(id, 1);
      expect(handler.isDragging, isFalse);
      expect(handler.draggingPhotoId, isNull);
    });

    test('reset clears all state', () {
      final photo = PhotoCard(id: 1, imagePath: 'a.jpg', x: 50, y: 75);
      handler.onDragStart(1, const Offset(100, 200), photo);
      handler.reset();
      expect(handler.isDragging, isFalse);
      expect(handler.draggingPhotoId, isNull);
    });

    test('isBeyondBoundary returns false when within bounds', () {
      final photo = PhotoCard(id: 1, imagePath: 'a.jpg', x: 1000, y: 1000);
      handler.onDragStart(1, const Offset(100, 100), photo);
      handler.onDragUpdate(const Offset(200, 200), 1.0);
      expect(handler.isBeyondBoundary, isFalse);
    });

    test('isBeyondBoundary returns true when dragged far beyond canvas', () {
      final photo = PhotoCard(id: 1, imagePath: 'a.jpg', x: 50, y: 50);
      handler.onDragStart(1, const Offset(100, 100), photo);
      // 拖到负坐标很远的位置
      handler.onDragUpdate(const Offset(-500, -500), 1.0);
      expect(handler.isBeyondBoundary, isTrue);
    });

    test('getSpringBackTarget clamps to valid boundary', () {
      final photo = PhotoCard(id: 1, imagePath: 'a.jpg', x: 50, y: 50);
      handler.onDragStart(1, const Offset(100, 100), photo);
      handler.onDragUpdate(const Offset(-500, -500), 1.0);
      final target = handler.getSpringBackTarget();
      // 应该被钳制到边界内
      expect(target.dx, greaterThanOrEqualTo(0));
      expect(target.dy, greaterThanOrEqualTo(0));
    });

    test('damping slows down movement beyond boundary', () {
      final photo = PhotoCard(id: 1, imagePath: 'a.jpg', x: 100, y: 100);
      handler.onDragStart(1, const Offset(100, 100), photo);
      // 在边界内移动
      final pos1 = handler.onDragUpdate(const Offset(200, 200), 1.0);
      // 移动到边界外
      final pos2 = handler.onDragUpdate(const Offset(6000, 6000), 1.0);
      // 边界外的移动应该被阻尼减速
      expect(pos2, isNotNull);
      // 边界外的实际位移应该小于线性位移
      final linearDelta = 6000 - 100;
      final actualDelta = pos2!.dx - 100;
      expect(actualDelta, lessThan(linearDelta.toDouble()));
    });
  });

  group('SelectionManager', () {
    late SelectionManager manager;

    setUp(() {
      manager = SelectionManager();
    });

    test('initial state has no selection', () {
      expect(manager.hasSelection, isFalse);
      expect(manager.selectedCardId, isNull);
      expect(manager.selectedPhotoId, isNull);
      expect(manager.highlightedCardIds, isEmpty);
      expect(manager.highlightedPhotoIds, isEmpty);
    });

    test('selectCard sets card and highlights connected cards', () {
      final connections = [
        Connection(fromCardId: 1, toCardId: 2),
        Connection(fromCardId: 1, toCardId: 3),
      ];
      manager.selectCard(1, connections);
      expect(manager.selectedCardId, 1);
      expect(manager.highlightedCardIds, containsAll([1, 2, 3]));
      expect(manager.hasSelection, isTrue);
    });

    test('selectCard highlights connected photos', () {
      final connections = [
        Connection(fromCardId: 1, toPhotoId: 10),
      ];
      manager.selectCard(1, connections);
      expect(manager.highlightedPhotoIds, contains(10));
    });

    test('selectCard handles bidirectional connections', () {
      final connections = [
        Connection(fromCardId: 5, toCardId: 1),
      ];
      manager.selectCard(1, connections);
      expect(manager.highlightedCardIds, containsAll([1, 5]));
    });

    test('selectPhoto sets photo id', () {
      manager.selectPhoto(42, []);
      expect(manager.selectedPhotoId, 42);
      expect(manager.hasSelection, isTrue);
    });

    test('selectPhoto highlights connected cards', () {
      final connections = [
        Connection(fromPhotoId: 10, toCardId: 1),
        Connection(fromPhotoId: 10, toCardId: 2),
      ];
      manager.selectPhoto(10, connections);
      expect(manager.selectedPhotoId, 10);
      expect(manager.highlightedCardIds, containsAll([1, 2]));
      expect(manager.highlightedPhotoIds, contains(10));
    });

    test('selectPhoto highlights bidirectional connections', () {
      final connections = [
        Connection(fromCardId: 5, toPhotoId: 10),
        Connection(fromPhotoId: 10, toPhotoId: 20),
      ];
      manager.selectPhoto(10, connections);
      expect(manager.highlightedCardIds, contains(5));
      expect(manager.highlightedPhotoIds, containsAll([10, 20]));
    });

    test('clearSelection resets everything', () {
      manager.selectCard(1, [Connection(fromCardId: 1, toCardId: 2)]);
      manager.selectPhoto(10, []);
      manager.clearSelection();
      expect(manager.hasSelection, isFalse);
      expect(manager.selectedCardId, isNull);
      expect(manager.selectedPhotoId, isNull);
      expect(manager.highlightedCardIds, isEmpty);
      expect(manager.highlightedPhotoIds, isEmpty);
    });
  });

  group('UndoRedoNotifier', () {
    late ProviderContainer container;
    late UndoRedoNotifier notifier;
    late List<String> log;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(undoRedoProvider.notifier);
      log = [];
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has empty stacks', () {
      final state = container.read(undoRedoProvider);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
      expect(state.undoStack, isEmpty);
      expect(state.redoStack, isEmpty);
    });

    test('executeCommand adds to undo stack', () async {
      await notifier.executeCommand(_TestCommand('A', log));
      final state = container.read(undoRedoProvider);
      expect(state.undoStack.length, 1);
      expect(state.canUndo, isTrue);
      expect(state.redoStack, isEmpty);
      expect(log, ['execute:A']);
    });

    test('undo moves command to redo stack', () async {
      await notifier.executeCommand(_TestCommand('A', log));
      await notifier.undo();
      final state = container.read(undoRedoProvider);
      expect(state.undoStack, isEmpty);
      expect(state.redoStack.length, 1);
      expect(log, ['execute:A', 'undo:A']);
    });

    test('redo moves command back to undo stack', () async {
      await notifier.executeCommand(_TestCommand('A', log));
      await notifier.undo();
      await notifier.redo();
      final state = container.read(undoRedoProvider);
      expect(state.undoStack.length, 1);
      expect(state.redoStack, isEmpty);
      expect(log, ['execute:A', 'undo:A', 'execute:A']);
    });

    test('executeCommand clears redo stack', () async {
      await notifier.executeCommand(_TestCommand('A', log));
      await notifier.undo();
      await notifier.executeCommand(_TestCommand('B', log));
      final state = container.read(undoRedoProvider);
      expect(state.undoStack.length, 1);
      expect(state.redoStack, isEmpty);
    });

    test('undo does nothing when stack is empty', () async {
      await notifier.undo();
      final state = container.read(undoRedoProvider);
      expect(state.undoStack, isEmpty);
      expect(log, isEmpty);
    });

    test('redo does nothing when stack is empty', () async {
      await notifier.redo();
      final state = container.read(undoRedoProvider);
      expect(state.redoStack, isEmpty);
      expect(log, isEmpty);
    });

    test('clear resets all stacks', () async {
      await notifier.executeCommand(_TestCommand('A', log));
      notifier.clear();
      final state = container.read(undoRedoProvider);
      expect(state.undoStack, isEmpty);
      expect(state.redoStack, isEmpty);
    });

    test('history is capped at maxHistory', () async {
      for (var i = 0; i < 55; i++) {
        await notifier.executeCommand(_TestCommand('$i', log));
      }
      final state = container.read(undoRedoProvider);
      expect(state.undoStack.length, 50);
    });
  });
}

class _TestCommand extends UndoableCommand {
  final String name;
  final List<String> log;

  _TestCommand(this.name, this.log);

  @override
  String get description => name;

  @override
  Future<void> execute() async {
    log.add('execute:$name');
  }

  @override
  Future<void> undo() async {
    log.add('undo:$name');
  }
}
