import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progress_os/core/providers/shared_prefs_provider.dart';
import 'package:progress_os/main.dart';

void main() {
  testWidgets('Splash Screen smoke test', (WidgetTester tester) async {
    dotenv.testLoad(fileInput: 'SUPABASE_URL=https://placeholder.co\nSUPABASE_ANON_KEY=placeholder');
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const MyApp(supabaseInitialized: false),
      ),
    );

    // Verify splash screen shows the circular progress loader
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
