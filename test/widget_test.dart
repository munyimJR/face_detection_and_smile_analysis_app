import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:face_detection_and_smile_analysis_app/main.dart';
import 'package:face_detection_and_smile_analysis_app/theme/theme_notifier.dart';

void main() {
  testWidgets('HomeScreen renders title, tagline, upload action, and theme toggle', (
    tester,
  ) async {
    themeModeNotifier.value = ThemeMode.light;
    await tester.pumpWidget(const FaceDetectionApp());

    // Verify App Title & Tagline
    expect(find.text('Face Detection & Smile Analysis'), findsOneWidget);
    expect(find.text('Powered by Google ML Kit'), findsOneWidget);

    // Verify Upload Zone & Button
    expect(find.text('Upload Image to Analyze'), findsOneWidget);
    expect(find.text('Select from Gallery'), findsOneWidget);

    // Verify Theme Toggle Button works
    final themeToggleFinder = find.byTooltip('Switch to Dark Mode');
    expect(themeToggleFinder, findsOneWidget);

    await tester.tap(themeToggleFinder);
    await tester.pumpAndSettle();

    expect(themeModeNotifier.value, ThemeMode.dark);
    expect(find.byTooltip('Switch to Light Mode'), findsOneWidget);
  });
}
