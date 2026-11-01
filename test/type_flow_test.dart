import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/connection_model.dart';
import 'package:reticence/services/database/app_database.dart';
import 'package:reticence/services/repositories/card_repository.dart';
import 'package:reticence/services/repositories/connection_repository.dart';
import 'package:reticence/services/database/database_provider.dart';
import 'package:reticence/widgets/dialogs/add_card_dialog.dart';
import 'package:reticence/widgets/dialogs/connection_detail_dialog.dart';
import 'package:reticence/widgets/dialogs/type_selectors.dart';

void main() {
  group('AddCardDialog', () {
    testWidgets('fits a small screen and updates title with selected type',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddCardDialog(
                canvasPosition: Offset.zero,
                onCardAdded: _noop,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClueTypeSelector), findsOneWidget);
      expect(find.text('新人物'), findsOneWidget);

      await tester.tap(find.text('地点'));
      await tester.pumpAndSettle();

      expect(find.text('新地点'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ConnectionDetailDialog', () {
    late AppDatabase db;
    late CardRepository cardRepo;
    late ConnectionRepository connectionRepo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      cardRepo = CardRepository(db.cardDao);
      connectionRepo = ConnectionRepository(db.connectionDao);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('saves the selected relationship type', (tester) async {
      final from = await cardRepo.insertCard(ClueCard(name: '林默'));
      final to = await cardRepo.insertCard(
        ClueCard(name: '旧码头', cardType: CardType.location),
      );
      final connection = await connectionRepo.insertConnection(
        Connection(fromCardId: from.id, toCardId: to.id),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          ConnectionDetailDialog(connection: connection),
                    ),
                    child: const Text('打开'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();

      expect(find.byType(RelationshipTypeSelector), findsOneWidget);
      await tester.tap(find.text('盟友'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final saved = await connectionRepo.getAllConnections();
      expect(saved.single.connectionType, ConnectionType.ally);
    });
  });
}

void _noop(ClueCard _) {}
