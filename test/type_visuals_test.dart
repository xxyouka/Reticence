import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/connection_model.dart';
import 'package:reticence/theme/app_colors.dart';
import 'package:reticence/widgets/clue_card_widget.dart';
import 'package:reticence/widgets/dialogs/type_selectors.dart';
import 'package:reticence/widgets/painters/pushpin_decorator.dart';

void main() {
  group('Type selectors', () {
    testWidgets('ClueTypeSelector shows all types and reports selection',
        (tester) async {
      CardType? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: ClueTypeSelector(
                  selected: CardType.person,
                  onChanged: (type) => selected = type,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('人物'), findsOneWidget);
      expect(find.text('地点'), findsOneWidget);
      expect(find.text('事件'), findsOneWidget);

      await tester.tap(find.text('地点'));
      await tester.pump();

      expect(selected, CardType.location);
    });

    testWidgets(
        'RelationshipTypeSelector shows all types and reports selection',
        (tester) async {
      ConnectionType? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: RelationshipTypeSelector(
                  selected: ConnectionType.neutral,
                  onChanged: (type) => selected = type,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('中立'), findsOneWidget);
      expect(find.text('盟友'), findsOneWidget);
      expect(find.text('敌对'), findsOneWidget);
      expect(find.text('自定义'), findsOneWidget);

      await tester.tap(find.text('盟友'));
      await tester.pump();

      expect(selected, ConnectionType.ally);
    });
  });

  group('ClueCardWidget type visuals', () {
    testWidgets('shows type badge, semantics and type-colored pin',
        (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ClueCardWidget(
                card: ClueCard(
                  id: 1,
                  name: '旧码头',
                  cardType: CardType.location,
                  tags: const ['现场'],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('旧码头'), findsOneWidget);
      expect(find.text('地点'), findsOneWidget);
      expect(find.text('现场'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('类型：地点')), findsOneWidget);

      final pushpin = tester.widget<Pushpin>(find.byType(Pushpin));
      expect(pushpin.color, AppColors.pinBlue);

      semantics.dispose();
    });
  });
}
