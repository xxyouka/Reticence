import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reticence/models/card_model.dart';
import 'package:reticence/models/photo_card_model.dart';
import 'package:reticence/screens/clue_wall_screen.dart';
import 'package:reticence/services/database/app_database.dart';
import 'package:reticence/services/database/database_provider.dart';
import 'package:reticence/services/repositories/card_repository.dart';
import 'package:reticence/services/repositories/photo_repository.dart';
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

Offset _screenPointToCanvas(WidgetTester tester, Offset screenPoint) {
  return MatrixUtils.transformPoint(
    Matrix4.inverted(_canvasTransform(tester).transform),
    screenPoint,
  );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await CardRepository(db.cardDao).insertCard(
      ClueCard(
        name: 'Pinch target',
        x: WallConstants.canvasWidth / 2 - WallConstants.cardWidth / 2,
        y: WallConstants.canvasHeight / 2 - WallConstants.cardHeight / 2,
        width: WallConstants.cardWidth,
        height: WallConstants.cardHeight,
      ),
    );
    await PhotoRepository(db.photoDao).insertPhoto(
      PhotoCard(
        imagePath: 'missing-test-image.jpg',
        caption: 'Evidence',
        x: WallConstants.canvasWidth / 2 + 260,
        y: WallConstants.canvasHeight / 2 - WallConstants.photoCardHeight / 2,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('opens with the canvas center in the viewport', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: ClueWallScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    const boardCenter = Offset(
      WallConstants.canvasWidth / 2,
      WallConstants.canvasHeight / 2,
    );
    final boardCenterOnScreen = _canvasPointOnScreen(tester, boardCenter);

    expect(boardCenterOnScreen.dx, closeTo(screenSize.width / 2, 0.5));
    expect(boardCenterOnScreen.dy, closeTo(screenSize.height / 2, 0.5));
  });

  testWidgets('card drag requires a long press before moving', (tester) async {
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
    final cardCenter = _canvasPointOnScreen(
      tester,
      const Offset(
        WallConstants.canvasWidth / 2,
        WallConstants.canvasHeight / 2,
      ),
    );

    final quickDrag = await tester.createGesture(
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    await quickDrag.down(cardCenter);
    await tester.pump();
    await quickDrag.moveTo(cardCenter + const Offset(90, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await quickDrag.moveTo(cardCenter + const Offset(140, 0));
    await tester.pump(const Duration(milliseconds: 350));
    await quickDrag.moveTo(cardCenter + const Offset(180, 0));
    await tester.pump();

    await quickDrag.up();
    await tester.pump(const Duration(milliseconds: 200));

    final unmovedTopLeft = tester.getTopLeft(cardText);
    expect(unmovedTopLeft.dx, closeTo(initialTopLeft.dx, 15));
    expect(unmovedTopLeft.dy, closeTo(initialTopLeft.dy, 15));

    final longPressDrag = await tester.createGesture(
      pointer: 2,
      kind: PointerDeviceKind.touch,
    );
    final longPressStart = _canvasPointOnScreen(
      tester,
      const Offset(
        WallConstants.canvasWidth / 2,
        WallConstants.canvasHeight / 2,
      ),
    );
    await longPressDrag.down(longPressStart);
    await tester.pump(const Duration(milliseconds: 500));
    await longPressDrag.moveTo(longPressStart + const Offset(60, 0));
    await tester.pump(const Duration(milliseconds: 50));

    final movedTopLeft = tester.getTopLeft(cardText);
    expect(movedTopLeft.dx, greaterThan(initialTopLeft.dx + 35));

    await longPressDrag.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('photo drag requires a long press before moving', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: ClueWallScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final photosBefore = await PhotoRepository(db.photoDao).getAllPhotos();
    final initialPhoto = photosBefore.single;
    final photoStart = _canvasPointOnScreen(
      tester,
      Offset(
        initialPhoto.x + initialPhoto.width / 2,
        initialPhoto.y + initialPhoto.height / 2,
      ),
    );

    final quickDrag = await tester.createGesture(
      pointer: 11,
      kind: PointerDeviceKind.touch,
    );
    await quickDrag.down(photoStart);
    await tester.pump();
    await quickDrag.moveTo(photoStart + const Offset(90, 0));
    await tester.pump(const Duration(milliseconds: 80));
    await quickDrag.up();
    await tester.pump(const Duration(milliseconds: 250));

    final afterQuickDrag =
        (await PhotoRepository(db.photoDao).getAllPhotos()).single;
    expect(afterQuickDrag.x, closeTo(initialPhoto.x, 0.5));
    expect(afterQuickDrag.y, closeTo(initialPhoto.y, 0.5));

    final longPressStart = _canvasPointOnScreen(
      tester,
      Offset(
        afterQuickDrag.x + afterQuickDrag.width / 2,
        afterQuickDrag.y + afterQuickDrag.height / 2,
      ),
    );
    final longPressDrag = await tester.createGesture(
      pointer: 12,
      kind: PointerDeviceKind.touch,
    );
    await longPressDrag.down(longPressStart);
    await tester.pump(const Duration(milliseconds: 350));
    await longPressDrag.moveTo(longPressStart + const Offset(70, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await longPressDrag.up();
    await tester.pump(const Duration(milliseconds: 300));

    final movedPhoto =
        (await PhotoRepository(db.photoDao).getAllPhotos()).single;
    expect(movedPhoto.x, greaterThan(initialPhoto.x + 45));
    expect(movedPhoto.y, closeTo(initialPhoto.y, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinch zoom works when the first finger starts on a card',
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
    final focal = _canvasPointOnScreen(
      tester,
      const Offset(
        WallConstants.canvasWidth / 2,
        WallConstants.canvasHeight / 2,
      ),
    );

    final firstFinger = await tester.createGesture(
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    final secondFinger = await tester.createGesture(
      pointer: 2,
      kind: PointerDeviceKind.touch,
    );

    await firstFinger.down(focal - const Offset(40, 0));
    await secondFinger.down(focal + const Offset(40, 0));
    await tester.pump();

    await firstFinger.moveTo(focal - const Offset(90, 0));
    await secondFinger.moveTo(focal + const Offset(90, 0));
    await tester.pump();

    expect(_canvasScale(tester), greaterThan(initialScale));

    final zoomedInScale = _canvasScale(tester);

    await firstFinger.moveTo(focal - const Offset(20, 0));
    await secondFinger.moveTo(focal + const Offset(20, 0));
    await tester.pump();

    expect(_canvasScale(tester), lessThan(zoomedInScale));

    await firstFinger.up();
    await secondFinger.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinch zoom out keeps the focal point anchored on a card',
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
    final focal = _canvasPointOnScreen(
      tester,
      const Offset(
        WallConstants.canvasWidth / 2,
        WallConstants.canvasHeight / 2,
      ),
    );
    final focalCanvasPoint = _screenPointToCanvas(tester, focal);

    final firstFinger = await tester.createGesture(
      pointer: 1,
      kind: PointerDeviceKind.touch,
    );
    final secondFinger = await tester.createGesture(
      pointer: 2,
      kind: PointerDeviceKind.touch,
    );

    await firstFinger.down(focal - const Offset(40, 0));
    await secondFinger.down(focal + const Offset(40, 0));
    await tester.pump();

    await firstFinger.moveTo(focal - const Offset(15, 0));
    await secondFinger.moveTo(focal + const Offset(15, 0));
    await tester.pump();

    expect(_canvasScale(tester), lessThan(initialScale));

    final anchoredPoint = _canvasPointOnScreen(tester, focalCanvasPoint);
    expect(anchoredPoint.dx, closeTo(focal.dx, 0.5));
    expect(anchoredPoint.dy, closeTo(focal.dy, 0.5));

    await firstFinger.up();
    await secondFinger.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
