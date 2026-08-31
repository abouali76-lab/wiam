import 'package:flutter_test/flutter_test.dart';

import 'package:wiam_app/main.dart';

void main() {
  testWidgets('app boots to the mode-select screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WiamApp());
    await tester.pump();
    expect(find.text('وئام'), findsOneWidget);
  });
}
