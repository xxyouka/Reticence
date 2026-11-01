/// 卡片相关撤销命令
///
/// 实现卡片的添加、删除、移动等操作的撤销/重做逻辑。
library;

import '../../models/card_model.dart';
import '../../models/photo_card_model.dart';
import '../../models/connection_model.dart';
import '../card_provider.dart';
import '../photo_provider.dart';
import '../connection_provider.dart';
import '../undo_redo_provider.dart';

/// 添加卡片命令
///
/// 撤销时删除该卡片，重做时重新添加。
class AddCardCommand extends UndoableCommand {
  final CardListNotifier cardNotifier;
  final ClueCard card;
  ClueCard? _createdCard;

  AddCardCommand(this.cardNotifier, this.card);

  @override
  String get description => '添加卡片 "${card.name}"';

  @override
  Future<void> execute() async {
    _createdCard = await cardNotifier.addCard(card);
  }

  @override
  Future<void> undo() async {
    if (_createdCard?.id != null) {
      await cardNotifier.deleteCard(_createdCard!.id!);
    }
  }
}

/// 删除卡片命令
///
/// 撤销时重新添加该卡片及其关联的连线。
class DeleteCardCommand extends UndoableCommand {
  final CardListNotifier cardNotifier;
  final ConnectionListNotifier? connectionNotifier;
  final ClueCard card;
  final List<Connection> relatedConnections;

  DeleteCardCommand(
    this.cardNotifier,
    this.connectionNotifier,
    this.card,
    this.relatedConnections,
  );

  @override
  String get description => '删除卡片 "${card.name}"';

  @override
  Future<void> execute() async {
    // 删除关联连线
    if (connectionNotifier != null) {
      for (final conn in relatedConnections) {
        if (conn.id != null) {
          await connectionNotifier!.deleteConnection(conn.id!);
        }
      }
    }
    // 删除卡片
    if (card.id != null) {
      await cardNotifier.deleteCard(card.id!);
    }
  }

  @override
  Future<void> undo() async {
    // 重新添加卡片
    final newCard = await cardNotifier.addCard(card);
    if (newCard == null) return;

    // 重新添加关联连线（需要更新连线中的卡片 ID）
    if (connectionNotifier != null && card.id != newCard.id) {
      for (final conn in relatedConnections) {
        Connection restored = conn;
        if (conn.fromCardId == card.id) {
          restored = conn.copyWith(fromCardId: newCard.id);
        }
        if (conn.toCardId == card.id) {
          restored = conn.copyWith(toCardId: newCard.id);
        }
        await connectionNotifier!.addConnection(restored);
      }
    }
  }
}

/// 移动卡片命令（批量）
///
/// 撤销时恢复到移动前的位置，重做时恢复到移动后的位置。
class MoveCardsCommand extends UndoableCommand {
  final CardListNotifier cardNotifier;
  final Map<int, (double, double)> oldPositions; // cardId -> (x, y)
  final Map<int, (double, double)> newPositions; // cardId -> (x, y)

  MoveCardsCommand(this.cardNotifier, this.oldPositions, this.newPositions);

  @override
  String get description => '移动 ${newPositions.length} 张卡片';

  @override
  Future<void> execute() async {
    for (final entry in newPositions.entries) {
      await cardNotifier.updateCardPosition(entry.key, entry.value.$1, entry.value.$2);
    }
  }

  @override
  Future<void> undo() async {
    for (final entry in oldPositions.entries) {
      await cardNotifier.updateCardPosition(entry.key, entry.value.$1, entry.value.$2);
    }
  }
}

/// 添加照片命令
///
/// 撤销时删除该照片，重做时重新添加。
class AddPhotoCommand extends UndoableCommand {
  final PhotoListNotifier photoNotifier;
  final PhotoCard photo;
  PhotoCard? _createdPhoto;

  AddPhotoCommand(this.photoNotifier, this.photo);

  @override
  String get description => '添加照片';

  @override
  Future<void> execute() async {
    _createdPhoto = await photoNotifier.addPhoto(photo);
  }

  @override
  Future<void> undo() async {
    if (_createdPhoto?.id != null) {
      await photoNotifier.deletePhoto(_createdPhoto!.id!);
    }
  }
}

/// 删除照片命令
///
/// 撤销时重新添加该照片及其关联的连线。
class DeletePhotoCommand extends UndoableCommand {
  final PhotoListNotifier photoNotifier;
  final ConnectionListNotifier? connectionNotifier;
  final PhotoCard photo;
  final List<Connection> relatedConnections;

  DeletePhotoCommand(
    this.photoNotifier,
    this.connectionNotifier,
    this.photo,
    this.relatedConnections,
  );

  @override
  String get description => '删除照片';

  @override
  Future<void> execute() async {
    // 删除关联连线
    if (connectionNotifier != null) {
      for (final conn in relatedConnections) {
        if (conn.id != null) {
          await connectionNotifier!.deleteConnection(conn.id!);
        }
      }
    }
    // 删除照片
    if (photo.id != null) {
      await photoNotifier.deletePhoto(photo.id!);
    }
  }

  @override
  Future<void> undo() async {
    // 重新添加照片
    final newPhoto = await photoNotifier.addPhoto(photo);
    if (newPhoto == null) return;

    // 重新添加关联连线
    if (connectionNotifier != null && photo.id != newPhoto.id) {
      for (final conn in relatedConnections) {
        Connection restored = conn;
        if (conn.fromPhotoId == photo.id) {
          restored = conn.copyWith(fromPhotoId: newPhoto.id);
        }
        if (conn.toPhotoId == photo.id) {
          restored = conn.copyWith(toPhotoId: newPhoto.id);
        }
        await connectionNotifier!.addConnection(restored);
      }
    }
  }
}

/// 移动照片命令（批量）
///
/// 撤销时恢复到移动前的位置，重做时恢复到移动后的位置。
class MovePhotosCommand extends UndoableCommand {
  final PhotoListNotifier photoNotifier;
  final Map<int, (double, double)> oldPositions; // photoId -> (x, y)
  final Map<int, (double, double)> newPositions; // photoId -> (x, y)

  MovePhotosCommand(this.photoNotifier, this.oldPositions, this.newPositions);

  @override
  String get description => '移动 ${newPositions.length} 张照片';

  @override
  Future<void> execute() async {
    for (final entry in newPositions.entries) {
      await photoNotifier.updatePhotoPosition(entry.key, entry.value.$1, entry.value.$2);
    }
  }

  @override
  Future<void> undo() async {
    for (final entry in oldPositions.entries) {
      await photoNotifier.updatePhotoPosition(entry.key, entry.value.$1, entry.value.$2);
    }
  }
}
