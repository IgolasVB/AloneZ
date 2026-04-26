import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alonez/main.dart';

void main() {
  testWidgets('shows the AloneZ start menu', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('LOJA'), findsOneWidget);
    expect(find.text('INVENTARIO'), findsOneWidget);
    expect(find.text('COINS GRATIS'), findsOneWidget);
    expect(find.text('MISSOES'), findsOneWidget);
  });
}
