import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sana_app/main.dart';
import 'package:sana_app/state/app_state.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('SanaApp smoke test and navigation verify', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: const SanaApp(),
      ),
    );

    await tester.pump();

    // Verify navigation tabs render
    expect(find.text('Live Alert'), findsOneWidget);
    expect(find.text('Journal (AEJ)'), findsOneWidget);
    expect(find.text('Insights (APMA)'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
