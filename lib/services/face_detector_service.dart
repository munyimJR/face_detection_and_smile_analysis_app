import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/face_analysis_result.dart';

/// Wraps Google ML Kit [FaceDetector] with smile classification enabled.
///
/// Call [detect] to process a [File] and get bounding-box faces plus
/// structured [FaceAnalysisResult] objects. Call [close] when done.
class FaceDetectorService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      // enableClassification exposes smilingProbability on each face.
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// Runs face detection on [imageFile].
  ///
  /// Returns a record with:
  /// - [faces]   – raw ML Kit faces (used for bounding-box painting)
  /// - [results] – structured analysis objects (used for analytics cards)
  Future<({List<Face> faces, List<FaceAnalysisResult> results})> detect(
    File imageFile,
  ) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await _detector.processImage(inputImage);

    final results = faces.asMap().entries.map((entry) {
      final prob = entry.value.smilingProbability ?? 0.0;
      return FaceAnalysisResult(
        faceNumber: entry.key + 1,
        isSmiling: prob >= 0.70,
        smileProbability: prob,
      );
    }).toList();

    return (faces: faces, results: results);
  }

  /// Releases the underlying ML Kit detector. Must be called when the
  /// owning widget is disposed.
  void close() => _detector.close();
}

