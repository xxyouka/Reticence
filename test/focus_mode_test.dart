import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/connection_model.dart';
import 'package:reticence/screens/clue_wall_screen.dart';
import 'package:reticence/services/database/app_database.dart';
import 'package:reticence/services/database/database_provider.dart';
import 'package:reticence/services/repositories/card_repository.dart';
import 'package:reticence/services/repositories/connection_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final cardRepo = CardRepository(db.cardDao);
    final connectionRepo = ConnectionRepository(db.connectionDao);

    final a = await cardRepo.insertCard(
      ClueCard(name: 'A', x: 2250, y: 2350),
    );
    final b = await cardRepo.insertCard(
      ClueCard(name: 'B', x: 2700, y: 2350),
    );
    final c = await cardRepo.insertCard(
      ClueCard(name: 'C', x: 2250, y: 2650),
    );
    final d = await cardRepo.insertCard(
      ClueCard(name: 'D', x: 2700, y: 2650),
    );
    await connectionRepo.insertConnection(
      Connection(fromCardId: a.id, toCardId: b.id),
    );
    await connectionRepo.insertConnection(
      Connection(fromCardId: c.id, toCardId: d.id),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ClueWallScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
  }

  double opacityOf(WidgetTester tester, String name) {
    final finder = find.ancestor(
      of: find.text(name),
      matching: find.byType(AnimatedOpacity),
    );
    expect(finder, findsWidgets);
    return tester.widget<AnimatedOpacity>(finder.first).opacity;
  }

  testWidgets('selecting a card dims cards outside its network',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('A'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('聚焦 · A'), findsOneWidget);
    expect(opacityOf(tester, 'A'), 1.0);
    expect(opacityOf(tester, 'B'), 1.0);
    expect(opacityOf(tester, 'C'), lessThan(0.5));

    await tester.tap(find.text('聚焦 · A'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('聚焦 · A'), findsNothing);
    expect(opacityOf(tester, 'C'), 1.0);
  });

  testWidgets('tapping a dimmed connection exits focus without opening details',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('A'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('聚焦 · A'), findsOneWidget);

    // C-D 连线在 A 的聚焦网络之外，屏幕坐标约为 (455, 472)
    await tester.tapAt(const Offset(455, 472));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('关系详情'), findsNothing);
    expect(find.text('聚焦 · A'), findsNothing);
    expect(opacityOf(tester, 'C'), 1.0);
  });

  testWidgets('tapping a dimmed card switches focus', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('A'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('聚焦 · A'), findsOneWidget);

    await tester.tap(find.text('C'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('聚焦 · C'), findsOneWidget);
    expect(opacityOf(tester, 'A'), lessThan(0.5));
    expect(opacityOf(tester, 'B'), lessThan(0.5));
    expect(opacityOf(tester, 'C'), 1.0);
    expect(opacityOf(tester, 'D'), 1.0);
  });
}
