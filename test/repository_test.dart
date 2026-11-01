import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/connection_model.dart';
import 'package:reticence/models/photo_card_model.dart';
import 'package:reticence/services/database/app_database.dart';
import 'package:reticence/services/repositories/card_repository.dart';
import 'package:reticence/services/repositories/connection_repository.dart';
import 'package:reticence/services/repositories/photo_repository.dart';

void main() {
  late AppDatabase db;
  late CardRepository cardRepo;
  late PhotoRepository photoRepo;
  late ConnectionRepository connRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cardRepo = CardRepository(db.cardDao);
    photoRepo = PhotoRepository(db.photoDao);
    connRepo = ConnectionRepository(db.connectionDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('CardRepository', () {
    test('insertCard returns card with generated id', () async {
      final card = await cardRepo.insertCard(ClueCard(name: 'Alice'));
      expect(card.id, isNotNull);
      expect(card.name, 'Alice');
    });

    test('getAllCards returns all inserted cards', () async {
      await cardRepo.insertCard(ClueCard(name: 'A'));
      await cardRepo.insertCard(ClueCard(name: 'B'));
      final cards = await cardRepo.getAllCards();
      expect(cards.length, 2);
    });

    test('getCardById returns correct card', () async {
      final inserted = await cardRepo.insertCard(ClueCard(name: 'Target'));
      final fetched = await cardRepo.getCardById(inserted.id!);
      expect(fetched.name, 'Target');
      expect(fetched.id, inserted.id);
    });

    test('updateCard modifies existing card', () async {
      final card = await cardRepo.insertCard(ClueCard(name: 'Old', x: 10));
      final updated = card.copyWith(name: 'New', x: 20);
      final result = await cardRepo.updateCard(updated);
      expect(result, isTrue);
      final fetched = await cardRepo.getCardById(card.id!);
      expect(fetched.name, 'New');
      expect(fetched.x, 20);
    });

    test('updateCard returns false for card without id', () async {
      final result = await cardRepo.updateCard(ClueCard(name: 'No id'));
      expect(result, isFalse);
    });

    test('deleteCard removes card', () async {
      final card = await cardRepo.insertCard(ClueCard(name: 'Delete me'));
      await cardRepo.deleteCard(card.id!);
      final cards = await cardRepo.getAllCards();
      expect(cards, isEmpty);
    });

    test('tags survive round-trip through JSON serialization', () async {
      final card = await cardRepo.insertCard(
        ClueCard(name: 'Tagged', tags: const ['suspect', 'witness']),
      );
      final fetched = await cardRepo.getCardById(card.id!);
      expect(fetched.tags, ['suspect', 'witness']);
    });

    test('empty tags default to empty list', () async {
      final card = await cardRepo.insertCard(ClueCard(name: 'No tags'));
      final fetched = await cardRepo.getCardById(card.id!);
      expect(fetched.tags, isEmpty);
    });

    test('description survives round-trip', () async {
      final card = await cardRepo.insertCard(
        ClueCard(name: 'Desc', description: 'A detailed description'),
      );
      final fetched = await cardRepo.getCardById(card.id!);
      expect(fetched.description, 'A detailed description');
    });

    test('nullable description can be set to null', () async {
      final card = await cardRepo.insertCard(
        ClueCard(name: 'Desc', description: 'will clear'),
      );
      final cleared = card.copyWith(clearDescription: true);
      await cardRepo.updateCard(cleared);
      final fetched = await cardRepo.getCardById(card.id!);
      expect(fetched.description, isNull);
    });
  });

  group('PhotoRepository', () {
    test('insertPhoto returns photo with generated id', () async {
      final photo = await photoRepo.insertPhoto(
        PhotoCard(imagePath: '/path/a.jpg'),
      );
      expect(photo, isNotNull);
      expect(photo!.id, isNotNull);
    });

    test('getAllPhotos returns all inserted photos', () async {
      await photoRepo.insertPhoto(PhotoCard(imagePath: 'a.jpg'));
      await photoRepo.insertPhoto(PhotoCard(imagePath: 'b.jpg'));
      final photos = await photoRepo.getAllPhotos();
      expect(photos.length, 2);
    });

    test('updatePhoto modifies existing photo', () async {
      final photo = (await photoRepo.insertPhoto(
        PhotoCard(imagePath: 'a.jpg', caption: 'old'),
      ))!;
      final updated = photo.copyWith(caption: 'new');
      await photoRepo.updatePhoto(updated);
      final fetched = (await photoRepo.getAllPhotos()).single;
      expect(fetched.caption, 'new');
    });

    test('deletePhoto removes photo', () async {
      final photo = (await photoRepo.insertPhoto(
        PhotoCard(imagePath: 'a.jpg'),
      ))!;
      await photoRepo.deletePhoto(photo.id!);
      final photos = await photoRepo.getAllPhotos();
      expect(photos, isEmpty);
    });

    test('clears nullable caption on update', () async {
      final inserted = (await photoRepo.insertPhoto(
        PhotoCard(imagePath: 'photo.jpg', caption: 'old caption'),
      ))!;
      final cleared = inserted.copyWith(clearCaption: true);
      await photoRepo.updatePhoto(cleared);
      final reloaded = (await photoRepo.getAllPhotos()).single;
      expect(reloaded.caption, isNull);
    });

    test('photoStyle survives round-trip', () async {
      await photoRepo.insertPhoto(
        PhotoCard(imagePath: 'a.jpg', photoStyle: PhotoStyle.vintage),
      );
      final fetched = (await photoRepo.getAllPhotos()).single;
      expect(fetched.photoStyle, PhotoStyle.vintage);
    });

    test('position and rotation survive round-trip', () async {
      await photoRepo.insertPhoto(
        PhotoCard(imagePath: 'a.jpg', x: 123.5, y: 456.7, rotation: -3.2),
      );
      final fetched = (await photoRepo.getAllPhotos()).single;
      expect(fetched.x, 123.5);
      expect(fetched.y, 456.7);
      expect(fetched.rotation, -3.2);
    });
  });

  group('ConnectionRepository', () {
    test('insertConnection returns connection with generated id', () async {
      final a = await cardRepo.insertCard(ClueCard(name: 'A'));
      final b = await cardRepo.insertCard(ClueCard(name: 'B'));
      final conn = await connRepo.insertConnection(
        Connection(fromCardId: a.id, toCardId: b.id),
      );
      expect(conn.id, isNotNull);
    });

    test('getAllConnections returns all inserted connections', () async {
      final a = await cardRepo.insertCard(ClueCard(name: 'A'));
      final b = await cardRepo.insertCard(ClueCard(name: 'B'));
      final c = await cardRepo.insertCard(ClueCard(name: 'C'));
      await connRepo.insertConnection(
        Connection(fromCardId: a.id, toCardId: b.id),
      );
      await connRepo.insertConnection(
        Connection(fromCardId: b.id, toCardId: c.id),
      );
      final conns = await connRepo.getAllConnections();
      expect(conns.length, 2);
    });

    test('getConnectionsForCard returns connections involving that card',
        () async {
      final a = await cardRepo.insertCard(ClueCard(name: 'A'));
      final b = await cardRepo.insertCard(ClueCard(name: 'B'));
      final c = await cardRepo.insertCard(ClueCard(name: 'C'));
      await connRepo.insertConnection(
        Connection(fromCardId: a.id, toCardId: b.id),
      );
      await connRepo.insertConnection(
        Connection(fromCardId: b.id, toCardId: c.id),
      );
      final forB = await connRepo.getConnectionsForCard(b.id!);
      expect(forB.length, 2);
    });

    test('updateConnection modifies label', () async {
      final a = await cardRepo.insertCard(ClueCard(name: 'A'));
      final b = await cardRepo.insertCard(ClueCard(name: 'B'));
      final conn = await connRepo.insertConnection(
        Connection(fromCardId: a.id, toCardId: b.id, label: 'old'),
      );
      final updated = conn.copyWith(label: 'new');
      final result = await connRepo.updateConnection(updated);
      expect(result, isTrue);
      final fetched = (await connRepo.getAllConnections()).single;
      expect(fetched.label, 'new');
    });

    test('updateConnection returns false for connection without id', () async {
      final result = await connRepo.updateConnection(
        Connection(fromCardId: 1, toCardId: 2),
      );
      expect(result, isFalse);
    });

    test('deleteConnection removes connection', () async {
      final a = await cardRepo.insertCard(ClueCard(name: 'A'));
      final b = await cardRepo.insertCard(ClueCard(name: 'B'));
      final conn = await connRepo.insertConnection(
        Connection(fromCardId: a.id, toCardId: b.id),
      );
      await connRepo.deleteConnection(conn.id!);
      final conns = await connRepo.getAllConnections();
      expect(conns, isEmpty);
    });

    test('preserves connection type', () async {
      final a = await cardRepo.insertCard(ClueCard(name: 'A'));
      final b = await cardRepo.insertCard(ClueCard(name: 'B'));
      await connRepo.insertConnection(
        Connection(
          fromCardId: a.id,
          toCardId: b.id,
          label: 'conflict',
          connectionType: ConnectionType.enemy,
        ),
      );
      final reloaded = (await connRepo.getAllConnections()).single;
      expect(reloaded.connectionType, ConnectionType.enemy);
      expect(reloaded.label, 'conflict');
    });

    test('card-to-photo connection survives round-trip', () async {
      final card = await cardRepo.insertCard(ClueCard(name: 'A'));
      final photo = (await photoRepo.insertPhoto(
        PhotoCard(imagePath: 'a.jpg'),
      ))!;
      await connRepo.insertConnection(
        Connection(fromCardId: card.id, toPhotoId: photo.id),
      );
      final conns = await connRepo.getAllConnections();
      expect(conns.single.fromCardId, card.id);
      expect(conns.single.toPhotoId, photo.id);
      expect(conns.single.toCardId, isNull);
      expect(conns.single.fromPhotoId, isNull);
    });

    test('photo-to-photo connection survives round-trip', () async {
      final p1 = (await photoRepo.insertPhoto(
        PhotoCard(imagePath: 'a.jpg'),
      ))!;
      final p2 = (await photoRepo.insertPhoto(
        PhotoCard(imagePath: 'b.jpg'),
      ))!;
      await connRepo.insertConnection(
        Connection(fromPhotoId: p1.id, toPhotoId: p2.id),
      );
      final conns = (await connRepo.getAllConnections()).single;
      expect(conns.isCardToCard, isFalse);
      expect(conns.involvesPhoto, isTrue);
    });
  });
}
