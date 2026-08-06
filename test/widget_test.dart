import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driver_app/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders the app title and sign-in button',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Pairride Driver'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}

