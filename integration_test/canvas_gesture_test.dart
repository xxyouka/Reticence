import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/screens/clue_wall_screen.dart';
import 'package:reticence/services/database/app_database.dart';
import 'package:reticence/services/database/database_provider.dart';
import 'package:reticence/services/repositories/card_repository.dart';
import 'package:reticence/theme/wall_constants.dart';
import 'package:reticence/utils/canvas_matrix.dart';

Finder _canvasTransformFinder() {
  return find.byWidgetPredicate((widget) {
    if (widget is! Transform || widget.child is! SizedBox) return false;
    final child = widget.child! as SizedBox;
    return child.width == WallConstants.canvasWidth &&
        child.height == WallConstants.canvasHeight;
  });
}

double _canvasScale(WidgetTester tester) {
  return canvasMatrixScale(_canvasTransform(tester).transform);
}

Transform _canvasTransform(WidgetTester tester) {
  final transform =
      _canvasTransformFinder().evaluate().single.widget as Transform;
  return transform;
}

Offset _canvasPointOnScreen(WidgetTester tester, Offset canvasPoint) {
  return MatrixUtils.transformPoint(
    _canvasTransform(tester).transform,
    canvasPoint,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await CardRepository(db.cardDao).insertCard(
      ClueCard(
        name: 'Pinch target',
        x: 100,
        y: 100,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('card drag requires a long press before moving on Android',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: ClueWallScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final cardText = find.text('Pinch target');
    expect(cardText, findsOneWidget);
    final initialTopLeft = tester.getTopLeft(cardText);

    final quickDrag = await tester.createGesture(
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    await quickDrag.down(const Offset(145, 155));
    await tester.pump();
    await quickDrag.moveTo(const Offset(235, 155));
    await tester.pump(const Duration(milliseconds: 50));
    await quickDrag.moveTo(const Offset(285, 155));
    await tester.pump(const Duration(milliseconds: 350));
    await quickDrag.moveTo(const Offset(325, 155));
    await tester.pump();

    await quickDrag.up();
    await tester.pump(const Duration(milliseconds: 200));

    final unmovedTopLeft = tester.getTopLeft(cardText);
    expect(unmovedTopLeft.dx, closeTo(initialTopLeft.dx, 8));
    expect(unmovedTopLeft.dy, closeTo(initialTopLeft.dy, 8));

    final longPressDrag = await tester.createGesture(
      pointer: 2,
      kind: PointerDeviceKind.touch,
    );
    await longPressDrag.down(const Offset(145, 155));
    await tester.pump(const Duration(milliseconds: 350));
    await longPressDrag.moveTo(const Offset(205, 155));
    await tester.pump();

    final movedTopLeft = tester.getTopLeft(cardText);
    expect(movedTopLeft.dx, greaterThan(initialTopLeft.dx + 35));

    await longPressDrag.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinch zoom works on Android when starting on a card',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: ClueWallScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Pinch target'), findsOneWidget);
    final initialScale = _canvasScale(tester);

    final firstFinger = await tester.createGesture(
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    final secondFinger = await tester.createGesture(
      pointer: 2,
      kind: PointerDeviceKind.touch,
    );

    await firstFinger.down(const Offset(145, 155));
    await secondFinger.down(const Offset(225, 155));
    await tester.pump();

    await firstFinger.moveTo(const Offset(95, 155));
    await secondFinger.moveTo(const Offset(275, 155));
    await tester.pump();

    expect(_canvasScale(tester), greaterThan(initialScale));

    final zoomedInScale = _canvasScale(tester);

    await firstFinger.moveTo(const Offset(165, 155));
    await secondFinger.moveTo(const Offset(205, 155));
    await tester.pump();

    expect(_canvasScale(tester), lessThan(zoomedInScale));

    await firstFinger.up();
    await secondFinger.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinch zoom out keeps the focal point anchored on Android',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: ClueWallScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Pinch target'), findsOneWidget);
    final initialScale = _canvasScale(tester);

    final firstFinger = await tester.createGesture(
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    final secondFinger = await tester.createGesture(
      pointer: 2,
      kind: PointerDeviceKind.touch,
    );

    await firstFinger.down(const Offset(145, 155));
    await secondFinger.down(const Offset(225, 155));
    await tester.pump();

    await firstFinger.moveTo(const Offset(155, 155));
    await secondFinger.moveTo(const Offset(185, 155));
    await tester.pump();

    expect(_canvasScale(tester), lessThan(initialScale));

    final anchoredPoint = _canvasPointOnScreen(tester, const Offset(185, 155));
    expect(anchoredPoint.dx, closeTo(170, 0.5));
    expect(anchoredPoint.dy, closeTo(155, 0.5));

    await firstFinger.up();
    await secondFinger.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
