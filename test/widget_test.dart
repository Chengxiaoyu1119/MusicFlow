import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:musicflow/app.dart';

void main() {
  testWidgets('App should render with ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MusicPlayerApp()),
    );
    // Allow async initialization to complete
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(MusicPlayerApp), findsOneWidget);
  });
}
