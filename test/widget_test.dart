import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarisync/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite for tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('App renders splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    // Verify that the splash screen text is present.
    expect(find.text('SariSync'), findsOneWidget);
    expect(find.text('Point of Sale'), findsOneWidget);

    // Pump the timer so it doesn't stay pending
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('App shows welcome screen when no name is saved', (WidgetTester tester) async {
    // We use a small delay to simulate the splash screen timer if needed, 
    // but here we just test the WelcomeScreen directly for simplicity.
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('Welcome to SariSync!'), findsOneWidget);
    expect(find.text('How should we call you?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
