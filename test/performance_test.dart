import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/connection_model.dart';

void main() {
  group('Performance Tests', () {
    testWidgets('Render 10 cards without lag', (tester) async {
      final cards = List.generate(
        10,
        (index) => ClueCard(
          id: index,
          name: 'Card $index',
          x: (index % 3) * 150.0,
          y: (index ~/ 3) * 200.0,
        ),
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: cards
                  .map((card) => Positioned(
                        left: card.x,
                        top: card.y,
                        child: Container(
                          width: 100,
                          height: 100,
                          color: Colors.white,
                          child: Text(card.name),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    testWidgets('Render 30 cards - Performance baseline', (tester) async {
      final cards = List.generate(
        30,
        (index) => ClueCard(
          id: index,
          name: 'Card $index',
          x: (index % 5) * 100.0,
          y: (index ~/ 5) * 120.0,
        ),
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: cards
                  .map((card) => Positioned(
                        left: card.x,
                        top: card.y,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(card.name),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 3)));
    });

    test('Model creation performance', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        ClueCard(
          id: i,
          name: 'Test $i',
          tags: const ['tag1', 'tag2'],
          x: i * 10.0,
          y: i * 10.0,
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('Connection creation performance', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 500; i++) {
        Connection(
          id: i,
          fromCardId: i,
          toCardId: i + 1,
          label: 'Connection $i',
        );
      }

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}
