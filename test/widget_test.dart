// This is a basic Flutter widget test for the Laxis launcher app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laxis/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Laxis launcher UI test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LauncherApp());

    // Verify that the app title is present
    expect(find.text('Laxis'), findsOneWidget);

    // Verify that the search field is present
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Verify that the grid view is present
    expect(find.byType(GridView), findsOneWidget);

    // Verify that some common apps are present
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Chrome'), findsOneWidget);

    // Test search functionality
    await tester.enterText(find.byType(TextField), 'set');
    await tester.pump();
    expect(find.text('Settings'), findsOneWidget);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
  });
}
