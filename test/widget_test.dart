import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reticence/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ReticenceApp()),
    );

    expect(find.byType(ReticenceApp), findsOneWidget);
  });
}
