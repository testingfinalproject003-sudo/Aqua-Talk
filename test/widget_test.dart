import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_talk/main.dart';
import 'package:provider/provider.dart';
import 'package:aqua_talk/provider/chat_provider.dart';
import 'package:aqua_talk/provider/theme_provider.dart';

void main() {
  testWidgets('Aqua Talk smoke test', (WidgetTester tester) async {
    // Build our app with Providers (Important for your app!)
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app starts (Check for a search bar or a specific text)
    // Replace 'Search' with whatever hint text you have in your Search bar
    expect(find.textContaining('Search'), findsOneWidget);
  });
}