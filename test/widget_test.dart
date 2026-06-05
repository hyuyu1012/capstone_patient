// Smoke test for the patient app. The real app needs Firebase initialized, so
// this just verifies the login screen renders without a live backend.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capstone_patient/screens/onboarding/login_screen.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.text('안심 케어'), findsOneWidget);
  });
}
