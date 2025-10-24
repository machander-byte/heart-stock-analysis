import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heartanalysis/main.dart'; // ✅ Adjust if your project structure is different

void main() {
  testWidgets('Onboarding screen renders correctly', (WidgetTester tester) async {
    // Build the widget tree
    await tester.pumpWidget(const HeartStrokeApp());

    // Wait for auth stream and animations (important for FirebaseAuth handling)
    await tester.pumpAndSettle();

    // Check for onboarding welcome message
    expect(find.text('Welcome to\nHeart Stroke Prediction'), findsOneWidget);

    // Check if Get Started button is visible and tappable
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
