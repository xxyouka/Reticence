import 'package:flutter_test/flutter_test.dart';
import 'package:reticence/controllers/search_controller.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/connection_model.dart';
import 'package:reticence/models/photo_card_model.dart';

void main() {
  final cards = [
    ClueCard(
      id: 1,
      name: '旧码头',
      cardType: CardType.location,
      tags: const ['现场'],
    ),
    ClueCard(id: 2, name: '林默', cardType: CardType.person),
    ClueCard(
      id: 3,
      name: '失踪案',
      cardType: CardType.event,
      description: '午夜发生',
    ),
  ];
  final connections = [
    Connection(
      id: 10,
      fromCardId: 1,
      toCardId: 2,
      label: '目击',
      connectionType: ConnectionType.enemy,
    ),
  ];

  group('AppSearchController.searchAll', () {
    test('matches card by name, tag and description', () {
      expect(
        AppSearchController.searchAll(
                cards, const <PhotoCard>[], connections, '码头')
            .cardIds,
        {1},
      );
      expect(
        AppSearchController.searchAll(
                cards, const <PhotoCard>[], connections, '现场')
            .cardIds,
        {1},
      );
      expect(
        AppSearchController.searchAll(
                cards, const <PhotoCard>[], connections, '午夜')
            .cardIds,
        {3},
      );
    });

    test('matches cards by card type label', () {
      expect(
        AppSearchController.searchAll(
                cards, const <PhotoCard>[], connections, '地点')
            .cardIds,
        {1},
      );
      expect(
        AppSearchController.searchAll(
                cards, const <PhotoCard>[], connections, '人物')
            .cardIds,
        {2},
      );
      expect(
        AppSearchController.searchAll(
                cards, const <PhotoCard>[], connections, '事件')
            .cardIds,
        {3},
      );
    });

    test('matches connections by relationship type label', () {
      expect(
        AppSearchController.searchAll(
                cards, const <PhotoCard>[], connections, '敌对')
            .connectionIds,
        {10},
      );
    });

    test('matches connections by label', () {
      expect(
        AppSearchController.searchAll(
                cards, const <PhotoCard>[], connections, '目击')
            .connectionIds,
        {10},
      );
    });

    test('returns empty result for unmatched query', () {
      final result = AppSearchController.searchAll(
          cards, const <PhotoCard>[], connections, '火星');
      expect(result.cardIds, isEmpty);
      expect(result.photoIds, isEmpty);
      expect(result.connectionIds, isEmpty);
    });
  });
}
