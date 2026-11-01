import 'package:flutter_test/flutter_test.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/connection_model.dart';
import 'package:reticence/models/photo_card_model.dart';

void main() {
  group('ClueCard', () {
    test('supports value equality', () {
      final now = DateTime.now();
      final card1 = ClueCard(
        id: 1,
        name: 'Alice',
        tags: const ['suspect'],
        x: 10,
        y: 20,
        createdAt: now,
        updatedAt: now,
      );
      final card2 = ClueCard(
        id: 1,
        name: 'Alice',
        tags: const ['suspect'],
        x: 10,
        y: 20,
        createdAt: now,
        updatedAt: now,
      );
      expect(card1, equals(card2));
      expect(card1.hashCode, equals(card2.hashCode));
    });

    test('different cards are not equal', () {
      final card1 = ClueCard(id: 1, name: 'Alice');
      final card2 = ClueCard(id: 2, name: 'Bob');
      expect(card1, isNot(equals(card2)));
    });

    test('copyWith preserves unchanged fields', () {
      final card =
          ClueCard(id: 1, name: 'Alice', tags: const ['suspect'], x: 10, y: 20);
      final updated = card.copyWith(x: 30);
      expect(updated.x, 30);
      expect(updated.name, 'Alice');
      expect(updated.tags, ['suspect']);
      expect(updated.y, 20);
    });

    test('copyWith clearDescription sets description to null', () {
      final card = ClueCard(id: 1, name: 'Alice', description: 'some desc');
      final cleared = card.copyWith(clearDescription: true);
      expect(cleared.description, isNull);
    });

    test('default values are applied', () {
      final card = ClueCard(name: 'Test');
      expect(card.id, isNull);
      expect(card.cardType, CardType.person);
      expect(card.tags, isEmpty);
      expect(card.x, 0);
      expect(card.y, 0);
      expect(card.rotation, 0);
      expect(card.createdAt, isNotNull);
      expect(card.updatedAt, isNotNull);
    });

    test('cardType defaults to person and can be changed via copyWith', () {
      final card = ClueCard(name: 'Old Pier');
      expect(card.cardType, CardType.person);

      final location = card.copyWith(cardType: CardType.location);
      expect(location.cardType, CardType.location);
      expect(card.cardType, CardType.person);
    });

    test('cardType participates in equality', () {
      final person = ClueCard(id: 1, name: 'Same');
      final place = ClueCard(id: 1, name: 'Same', cardType: CardType.location);
      expect(person, isNot(equals(place)));
    });

    test('CardType.fromName parses names and falls back to person', () {
      expect(CardType.fromName('location'), CardType.location);
      expect(CardType.fromName('event'), CardType.event);
      expect(CardType.fromName('person'), CardType.person);
      expect(CardType.fromName('unknown'), CardType.person);
      expect(CardType.fromName(null), CardType.person);
    });
  });

  group('Connection', () {
    test('supports value equality', () {
      final now = DateTime.now();
      final conn1 = Connection(
        id: 1,
        fromCardId: 10,
        toCardId: 20,
        createdAt: now,
      );
      final conn2 = Connection(
        id: 1,
        fromCardId: 10,
        toCardId: 20,
        createdAt: now,
      );
      expect(conn1, equals(conn2));
      expect(conn1.hashCode, equals(conn2.hashCode));
    });

    test('different connections are not equal', () {
      final conn1 = Connection(id: 1, fromCardId: 10, toCardId: 20);
      final conn2 = Connection(id: 2, fromCardId: 10, toCardId: 30);
      expect(conn1, isNot(equals(conn2)));
    });

    test('copyWith preserves unchanged fields', () {
      final conn = Connection(
        id: 1,
        fromCardId: 10,
        toCardId: 20,
        label: 'friend',
      );
      final updated = conn.copyWith(label: 'enemy');
      expect(updated.label, 'enemy');
      expect(updated.fromCardId, 10);
      expect(updated.toCardId, 20);
    });

    test('copyWith clearLabel sets label to null', () {
      final conn =
          Connection(id: 1, fromCardId: 10, toCardId: 20, label: 'test');
      final cleared = conn.copyWith(clearLabel: true);
      expect(cleared.label, isNull);
    });

    test('default values are applied', () {
      final conn = Connection(fromCardId: 1, toCardId: 2);
      expect(conn.id, isNull);
      expect(conn.label, isNull);
      expect(conn.connectionType, ConnectionType.neutral);
      expect(conn.createdAt, isNotNull);
    });

    test('connectionType can be changed and participates in equality', () {
      final conn = Connection(id: 1, fromCardId: 10, toCardId: 20);
      final ally = conn.copyWith(connectionType: ConnectionType.ally);

      expect(ally.connectionType, ConnectionType.ally);
      expect(conn.connectionType, ConnectionType.neutral);
      expect(ally, isNot(equals(conn)));
    });

    test('ConnectionType labels and fromName fallback', () {
      expect(ConnectionType.neutral.label, '中立');
      expect(ConnectionType.ally.label, '盟友');
      expect(ConnectionType.enemy.label, '敌对');
      expect(ConnectionType.custom.label, '自定义');
      expect(ConnectionType.fromName('ally'), ConnectionType.ally);
      expect(ConnectionType.fromName('enemy'), ConnectionType.enemy);
      expect(ConnectionType.fromName('nonsense'), ConnectionType.neutral);
      expect(ConnectionType.fromName(null), ConnectionType.neutral);
    });
  });

  group('PhotoCard', () {
    test('supports value equality', () {
      final now = DateTime.now();
      final photo1 = PhotoCard(
        id: 1,
        imagePath: '/path/to/photo.jpg',
        caption: 'Evidence',
        x: 10,
        y: 20,
        rotation: 5,
        createdAt: now,
        updatedAt: now,
      );
      final photo2 = PhotoCard(
        id: 1,
        imagePath: '/path/to/photo.jpg',
        caption: 'Evidence',
        x: 10,
        y: 20,
        rotation: 5,
        createdAt: now,
        updatedAt: now,
      );
      expect(photo1, equals(photo2));
      expect(photo1.hashCode, equals(photo2.hashCode));
    });

    test('different photos are not equal', () {
      final photo1 = PhotoCard(id: 1, imagePath: 'a.jpg');
      final photo2 = PhotoCard(id: 2, imagePath: 'b.jpg');
      expect(photo1, isNot(equals(photo2)));
    });

    test('copyWith preserves unchanged fields', () {
      final photo = PhotoCard(
        id: 1,
        imagePath: 'a.jpg',
        caption: 'Test',
        x: 10,
        y: 20,
      );
      final updated = photo.copyWith(x: 30, caption: 'Updated');
      expect(updated.x, 30);
      expect(updated.caption, 'Updated');
      expect(updated.imagePath, 'a.jpg');
      expect(updated.y, 20);
    });

    test('copyWith clearCaption sets caption to null', () {
      final photo = PhotoCard(id: 1, imagePath: 'a.jpg', caption: 'Test');
      final cleared = photo.copyWith(clearCaption: true);
      expect(cleared.caption, isNull);
    });

    test('default values are applied', () {
      final photo = PhotoCard(imagePath: 'a.jpg');
      expect(photo.id, isNull);
      expect(photo.caption, isNull);
      expect(photo.x, 0);
      expect(photo.y, 0);
      expect(photo.rotation, 0);
      expect(photo.width, 140.0);
      expect(photo.height, 180.0);
      expect(photo.photoStyle, PhotoStyle.polaroid);
      expect(photo.createdAt, isNotNull);
      expect(photo.updatedAt, isNotNull);
    });

    test('photoStyle can be set to vintage', () {
      final photo = PhotoCard(
        imagePath: 'a.jpg',
        photoStyle: PhotoStyle.vintage,
      );
      expect(photo.photoStyle, PhotoStyle.vintage);
    });
  });
}
