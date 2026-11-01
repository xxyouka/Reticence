import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/connection_model.dart';
import 'package:reticence/providers/connection_provider.dart';
import 'package:reticence/providers/relationship_filter_provider.dart';
import 'package:reticence/screens/relationship_legend_bar.dart';
import 'package:reticence/services/database/app_database.dart';
import 'package:reticence/services/database/database_provider.dart';
import 'package:reticence/services/repositories/card_repository.dart';
import 'package:reticence/services/repositories/connection_repository.dart';
import 'package:reticence/theme/app_colors.dart';
import 'package:reticence/theme/app_theme.dart';

void main() {
  group('toggleRelationshipFilter', () {
    test('starts isolating a type from the all-state', () {
      expect(
        toggleRelationshipFilter(const {}, ConnectionType.neutral),
        {ConnectionType.neutral},
      );
    });

    test('adds types to the active filter', () {
      expect(
        toggleRelationshipFilter(
          const {ConnectionType.neutral},
          ConnectionType.ally,
        ),
        {ConnectionType.neutral, ConnectionType.ally},
      );
    });

    test('removes an active type', () {
      expect(
        toggleRelationshipFilter(
          const {ConnectionType.neutral, ConnectionType.ally},
          ConnectionType.neutral,
        ),
        {ConnectionType.ally},
      );
    });

    test('tapping the only active type returns to all', () {
      expect(
        toggleRelationshipFilter(
          const {ConnectionType.enemy},
          ConnectionType.enemy,
        ),
        isEmpty,
      );
    });

    test('selecting all four types returns to all', () {
      expect(
        toggleRelationshipFilter(
          const {
            ConnectionType.neutral,
            ConnectionType.ally,
            ConnectionType.enemy,
          },
          ConnectionType.custom,
        ),
        isEmpty,
      );
    });
  });

  group('isConnectionTypeVisible', () {
    test('empty filter shows every type', () {
      for (final type in ConnectionType.values) {
        expect(isConnectionTypeVisible(type, const {}), isTrue);
      }
    });

    test('non-empty filter only shows selected types', () {
      expect(
        isConnectionTypeVisible(
            ConnectionType.neutral, const {ConnectionType.neutral}),
        isTrue,
      );
      expect(
        isConnectionTypeVisible(
            ConnectionType.enemy, const {ConnectionType.neutral}),
        isFalse,
      );
    });
  });

  group('RelationshipLegendBar', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final cardRepo = CardRepository(db.cardDao);
      final connectionRepo = ConnectionRepository(db.connectionDao);

      final a = await cardRepo.insertCard(ClueCard(name: 'A'));
      final b = await cardRepo.insertCard(ClueCard(name: 'B'));
      final c = await cardRepo.insertCard(ClueCard(name: 'C'));

      await connectionRepo.insertConnection(
        Connection(
          fromCardId: a.id,
          toCardId: b.id,
          connectionType: ConnectionType.neutral,
        ),
      );
      await connectionRepo.insertConnection(
        Connection(
          fromCardId: a.id,
          toCardId: c.id,
          connectionType: ConnectionType.neutral,
        ),
      );
      await connectionRepo.insertConnection(
        Connection(
          fromCardId: b.id,
          toCardId: c.id,
          connectionType: ConnectionType.ally,
        ),
      );
      await connectionRepo.insertConnection(
        Connection(
          fromCardId: a.id,
          toCardId: b.id,
          connectionType: ConnectionType.enemy,
        ),
      );

      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      await container.read(connectionListProvider.future);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> pumpLegend(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              backgroundColor: AppColors.corkBoard,
              body: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: RelationshipLegendBar(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder chip(String name) =>
        find.byKey(ValueKey('relationship-legend-$name'));

    testWidgets('shows total and per-type counts', (tester) async {
      await pumpLegend(tester);

      expect(find.text('全部'), findsOneWidget);
      expect(find.text('中立'), findsOneWidget);
      expect(find.text('盟友'), findsOneWidget);
      expect(find.text('敌对'), findsOneWidget);
      expect(find.text('自定义'), findsOneWidget);

      expect(
        find.descendant(of: chip('all'), matching: find.text('4')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chip('neutral'), matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chip('ally'), matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chip('enemy'), matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chip('custom'), matching: find.text('0')),
        findsOneWidget,
      );
    });

    testWidgets('isolates, accumulates and resets filters', (tester) async {
      await pumpLegend(tester);

      expect(container.read(relationshipFilterProvider), isEmpty);

      await tester.tap(chip('neutral'));
      await tester.pumpAndSettle();
      expect(
        container.read(relationshipFilterProvider),
        {ConnectionType.neutral},
      );

      await tester.tap(chip('ally'));
      await tester.pumpAndSettle();
      expect(
        container.read(relationshipFilterProvider),
        {ConnectionType.neutral, ConnectionType.ally},
      );

      await tester.tap(chip('neutral'));
      await tester.pumpAndSettle();
      expect(
        container.read(relationshipFilterProvider),
        {ConnectionType.ally},
      );

      await tester.tap(chip('all'));
      await tester.pumpAndSettle();
      expect(container.read(relationshipFilterProvider), isEmpty);
    });

    testWidgets('zero-count type cannot be selected', (tester) async {
      await pumpLegend(tester);

      await tester.tap(chip('custom'));
      await tester.pumpAndSettle();

      expect(container.read(relationshipFilterProvider), isEmpty);
    });
  });
}
