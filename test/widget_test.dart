import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sams/screens/manage-login/login_page.dart';

void main() {
  testWidgets('LoginPage UI renders email, password fields and login button', (WidgetTester tester) async {
    // Build the LoginPage widget inside a MaterialApp.
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    // Verify that the title and description are rendered.
    expect(find.text('SAMS Portal'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Verify that Email Address and Password input fields exist.
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify that the Login button is rendered.
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });
}
