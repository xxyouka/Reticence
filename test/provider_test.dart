import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/connection_model.dart';
import 'package:reticence/models/photo_card_model.dart';
import 'package:reticence/providers/card_provider.dart';
import 'package:reticence/providers/connection_provider.dart';
import 'package:reticence/providers/photo_provider.dart';
import 'package:reticence/services/database/app_database.dart';
import 'package:reticence/services/database/database_provider.dart';
import 'package:reticence/services/repositories/card_repository.dart';
import 'package:reticence/services/repositories/connection_repository.dart';
import 'package:reticence/services/repositories/photo_repository.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        cardRepositoryProvider.overrideWithValue(CardRepository(db.cardDao)),
        photoRepositoryProvider
            .overrideWithValue(PhotoRepository(db.photoDao)),
        connectionRepositoryProvider
            .overrideWithValue(ConnectionRepository(db.connectionDao)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('CardListNotifier', () {
    test('build loads cards from database', () async {
      await container.read(cardListProvider.future);
      final cards = container.read(cardListProvider).value;
      expect(cards, isNotNull);
      expect(cards, isEmpty);
    });

    test('addCard appends to list and persists', () async {
      final notifier = container.read(cardListProvider.notifier);
      final card = await notifier.addCard(ClueCard(name: 'Alice'));
      expect(card, isNotNull);
      expect(card!.name, 'Alice');
      expect(card.id, isNotNull);
      final cards = container.read(cardListProvider).value;
      expect(cards, hasLength(1));
    });

    test('updateCard modifies card in list', () async {
      final notifier = container.read(cardListProvider.notifier);
      final card = (await notifier.addCard(ClueCard(name: 'Old')))!;
      final result = await notifier.updateCard(card.copyWith(name: 'New'));
      expect(result, isTrue);
      final updated = container.read(cardListProvider).value!.first;
      expect(updated.name, 'New');
    });

    test('deleteCard removes card from list', () async {
      final notifier = container.read(cardListProvider.notifier);
      final card = (await notifier.addCard(ClueCard(name: 'Delete')))!;
      final result = await notifier.deleteCard(card.id!);
      expect(result, isTrue);
      expect(container.read(cardListProvider).value, isEmpty);
    });

    test('updateCardPositionInMemory updates without persisting', () async {
      final notifier = container.read(cardListProvider.notifier);
      final card = (await notifier.addCard(ClueCard(name: 'Drag', x: 10, y: 20)))!;
      notifier.updateCardPositionInMemory(card.id!, 50, 60);
      final updated = container.read(cardListProvider).value!.first;
      expect(updated.x, 50);
      expect(updated.y, 60);
    });

    test('persistCardPosition writes to database', () async {
      final notifier = container.read(cardListProvider.notifier);
      final card = (await notifier.addCard(ClueCard(name: 'Persist', x: 10)))!;
      notifier.updateCardPositionInMemory(card.id!, 99, 88);
      await notifier.persistCardPosition(card.id!);
      // Rebuild from database to verify persistence
      container.invalidate(cardListProvider);
      final refreshed = await container.read(cardListProvider.future);
      expect(refreshed.first.x, 99);
      expect(refreshed.first.y, 88);
    });

    test('updateCardPosition updates memory and database', () async {
      final notifier = container.read(cardListProvider.notifier);
      final card = (await notifier.addCard(ClueCard(name: 'Pos', x: 10)))!;
      await notifier.updateCardPosition(card.id!, 77, 88);
      final updated = container.read(cardListProvider).value!.first;
      expect(updated.x, 77);
      expect(updated.y, 88);
    });
  });

  group('PhotoListNotifier', () {
    test('build loads photos from database', () async {
      await container.read(photoListProvider.future);
      expect(container.read(photoListProvider).value, isEmpty);
    });

    test('addPhoto appends to list', () async {
      final notifier = container.read(photoListProvider.notifier);
      final photo = await notifier.addPhoto(PhotoCard(imagePath: 'a.jpg'));
      expect(photo, isNotNull);
      expect(photo!.id, isNotNull);
      expect(container.read(photoListProvider).value, hasLength(1));
    });

    test('updatePhoto modifies photo in list', () async {
      final notifier = container.read(photoListProvider.notifier);
      final photo =
          (await notifier.addPhoto(PhotoCard(imagePath: 'a.jpg', caption: 'old')))!;
      final result = await notifier.updatePhoto(photo.copyWith(caption: 'new'));
      expect(result, isTrue);
      expect(container.read(photoListProvider).value!.first.caption, 'new');
    });

    test('deletePhoto removes photo from list', () async {
      final notifier = container.read(photoListProvider.notifier);
      final photo = (await notifier.addPhoto(PhotoCard(imagePath: 'a.jpg')))!;
      final result = await notifier.deletePhoto(photo.id!);
      expect(result, isTrue);
      expect(container.read(photoListProvider).value, isEmpty);
    });

    test('updatePhotoPositionInMemory updates without persisting', () async {
      final notifier = container.read(photoListProvider.notifier);
      final photo =
          (await notifier.addPhoto(PhotoCard(imagePath: 'a.jpg', x: 10, y: 20)))!;
      notifier.updatePhotoPositionInMemory(photo.id!, 50, 60);
      final updated = container.read(photoListProvider).value!.first;
      expect(updated.x, 50);
      expect(updated.y, 60);
    });

    test('persistPhotoPosition writes to database', () async {
      final notifier = container.read(photoListProvider.notifier);
      final photo =
          (await notifier.addPhoto(PhotoCard(imagePath: 'a.jpg', x: 10)))!;
      notifier.updatePhotoPositionInMemory(photo.id!, 99, 88);
      await notifier.persistPhotoPosition(photo.id!);
      container.invalidate(photoListProvider);
      final refreshed = await container.read(photoListProvider.future);
      expect(refreshed.first.x, 99);
      expect(refreshed.first.y, 88);
    });
  });

  group('ConnectionListNotifier', () {
    test('build loads connections from database', () async {
      await container.read(connectionListProvider.future);
      expect(container.read(connectionListProvider).value, isEmpty);
    });

    test('addConnection appends to list', () async {
      final cardNotifier = container.read(cardListProvider.notifier);
      final a = (await cardNotifier.addCard(ClueCard(name: 'A')))!;
      final b = (await cardNotifier.addCard(ClueCard(name: 'B')))!;
      final connNotifier = container.read(connectionListProvider.notifier);
      final conn =
          await connNotifier.addConnection(Connection(fromCardId: a.id, toCardId: b.id));
      expect(conn, isNotNull);
      expect(conn!.id, isNotNull);
      expect(container.read(connectionListProvider).value, hasLength(1));
    });

    test('updateConnection modifies connection in list', () async {
      final cardNotifier = container.read(cardListProvider.notifier);
      final a = (await cardNotifier.addCard(ClueCard(name: 'A')))!;
      final b = (await cardNotifier.addCard(ClueCard(name: 'B')))!;
      final connNotifier = container.read(connectionListProvider.notifier);
      final conn = (await connNotifier.addConnection(
          Connection(fromCardId: a.id, toCardId: b.id, label: 'old')))!;
      final result =
          await connNotifier.updateConnection(conn.copyWith(label: 'new'));
      expect(result, isTrue);
      expect(container.read(connectionListProvider).value!.first.label, 'new');
    });

    test('deleteConnection removes connection from list', () async {
      final cardNotifier = container.read(cardListProvider.notifier);
      final a = (await cardNotifier.addCard(ClueCard(name: 'A')))!;
      final b = (await cardNotifier.addCard(ClueCard(name: 'B')))!;
      final connNotifier = container.read(connectionListProvider.notifier);
      final conn = (await connNotifier.addConnection(
          Connection(fromCardId: a.id, toCardId: b.id)))!;
      final result = await connNotifier.deleteConnection(conn.id!);
      expect(result, isTrue);
      expect(container.read(connectionListProvider).value, isEmpty);
    });
  });
}
