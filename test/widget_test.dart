// Smoke test: verifies that FaceDetectionApp renders the HomeScreen without
// crashing. Full integration testing for ML Kit requires a connected device.

import 'package:flutter_test/flutter_test.dart';
import 'package:face_detection_and_smile_analysis_app/main.dart';

void main() {
  testWidgets('HomeScreen renders Upload Image button', (tester) async {
    await tester.pumpWidget(const FaceDetectionApp());
    expect(find.text('Upload Image'), findsOneWidget);
    expect(find.text('Face Detection & Smile Analysis'), findsOneWidget);
  });
}
