import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/connection_model.dart';
import 'package:reticence/models/thread_pluck_event.dart';
import 'package:reticence/providers/card_provider.dart';
import 'package:reticence/providers/connection_provider.dart';
import 'package:reticence/providers/photo_provider.dart';
import 'package:reticence/screens/thread_layer.dart';
import 'package:reticence/services/database/app_database.dart';
import 'package:reticence/services/database/database_provider.dart';
import 'package:reticence/services/repositories/card_repository.dart';
import 'package:reticence/services/repositories/connection_repository.dart';

void main() {
  testWidgets('plucking a thread starts a wave and settles the ticker',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final cardRepo = CardRepository(db.cardDao);
    final connectionRepo = ConnectionRepository(db.connectionDao);

    final a = await cardRepo.insertCard(
      ClueCard(name: 'A', x: 100, y: 100),
    );
    final b = await cardRepo.insertCard(
      ClueCard(name: 'B', x: 400, y: 260),
    );
    final c = await cardRepo.insertCard(
      ClueCard(name: 'C', x: 700, y: 100),
    );

    final first = await connectionRepo.insertConnection(
      Connection(fromCardId: a.id, toCardId: b.id),
    );
    await connectionRepo.insertConnection(
      Connection(fromCardId: b.id, toCardId: c.id),
    );

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(cardListProvider.future);
    await container.read(photoListProvider.future);
    await container.read(connectionListProvider.future);

    final scaleNotifier = ValueNotifier<double>(1);
    final motionNotifier = ValueNotifier<int>(0);
    final pluckNotifier = ValueNotifier<ThreadPluckEvent?>(null);
    addTearDown(scaleNotifier.dispose);
    addTearDown(motionNotifier.dispose);
    addTearDown(pluckNotifier.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: ThreadLayer(
                canvasScaleNotifier: scaleNotifier,
                canvasMotionNotifier: motionNotifier,
                connectionLabels: const {},
                pluckNotifier: pluckNotifier,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    pluckNotifier.value = ThreadPluckEvent(
      connectionId: first.id!,
      position: const Offset(250, 190),
    );

    // 波动会通过共享卡片传导到第二条线；推进足够帧数后应自然静止，
// 且不再有帧请求（说明 Ticker 已停止）。
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
