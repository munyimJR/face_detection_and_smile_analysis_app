import 'package:flutter_test/flutter_test.dart';
import 'package:face_detection_and_smile_analysis_app/main.dart';

void main() {
  testWidgets('HomeScreen renders title, tagline and upload action', (
    tester,
  ) async {
    await tester.pumpWidget(const FaceDetectionApp());

    // Verify App Title & Tagline
    expect(find.text('Face Detection & Smile Analysis'), findsOneWidget);
    expect(find.text('Powered by Google ML Kit'), findsOneWidget);

    // Verify Upload Zone & Button
    expect(find.text('Upload Image to Analyze'), findsOneWidget);
    expect(find.text('Select from Gallery'), findsOneWidget);
  });
}
