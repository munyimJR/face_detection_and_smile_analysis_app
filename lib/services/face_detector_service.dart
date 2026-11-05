import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/face_analysis_result.dart';

/// Service that performs face detection and smile classification using
/// Google ML Kit on mobile devices, with fallback support for desktop environments.
class FaceDetectorService {
  FaceDetector? _detector;

  FaceDetectorService() {
    if (_isMlKitSupported) {
      _detector = FaceDetector(
        options: FaceDetectorOptions(
          // Enable classification so smilingProbability is calculated for each face.
          enableClassification: true,
          performanceMode: FaceDetectorMode.accurate,
          minFaceSize: 0.1,
        ),
      );
    }
  }

  /// Whether Google ML Kit native binary is supported on the current platform.
  static bool get _isMlKitSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Runs face detection on [imageFile].
  ///
  /// Returns a record with:
  /// - [results]: list of structured per-face results with smile classification.
  /// - [infoMessage]: optional informational notice (e.g. desktop preview).
  Future<({List<FaceAnalysisResult> results, String? infoMessage})> detect({
    required File imageFile,
    required Size imageSize,
  }) async {
    if (!_isMlKitSupported) {
      // Desktop / Web preview simulation so developers can test the full UI flow
      return (
        results: _generateDesktopSimulation(imageSize),
        infoMessage:
            'Running in desktop preview mode. Google ML Kit native is active on Android & iOS.',
      );
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _detector!.processImage(inputImage);

      final results = faces.asMap().entries.map((entry) {
        final i = entry.key;
        final face = entry.value;
        final prob = face.smilingProbability ?? 0.0;
        return FaceAnalysisResult(
          faceNumber: i + 1,
          isSmiling: prob >= 0.70,
          smileProbability: prob,
          boundingBox: face.boundingBox,
        );
      }).toList();

      return (results: results, infoMessage: null);
    } catch (e) {
      debugPrint('ML Kit Face Detection Error: $e');
      if (e.toString().contains('MissingPluginException')) {
        return (
          results: _generateDesktopSimulation(imageSize),
          infoMessage:
              'Running in desktop preview mode. Google ML Kit native runs on Android & iOS.',
        );
      }
      rethrow;
    }
  }

  /// Generates sample face bounding boxes for desktop development & testing.
  List<FaceAnalysisResult> _generateDesktopSimulation(Size imageSize) {
    final w = imageSize.width > 0 ? imageSize.width : 800.0;
    final h = imageSize.height > 0 ? imageSize.height : 600.0;

    return [
      FaceAnalysisResult(
        faceNumber: 1,
        isSmiling: true,
        smileProbability: 0.88,
        boundingBox: Rect.fromLTWH(w * 0.18, h * 0.22, w * 0.28, h * 0.36),
      ),
      FaceAnalysisResult(
        faceNumber: 2,
        isSmiling: false,
        smileProbability: 0.42,
        boundingBox: Rect.fromLTWH(w * 0.54, h * 0.25, w * 0.27, h * 0.35),
      ),
    ];
  }

  /// Closes the detector to release native resources.
  void close() {
    _detector?.close();
  }
}
