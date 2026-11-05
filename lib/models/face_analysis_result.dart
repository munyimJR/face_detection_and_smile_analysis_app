import 'dart:ui';

/// Holds the per-face analysis result.
class FaceAnalysisResult {
  /// 1-based face index (Face 1, Face 2, …).
  final int faceNumber;

  /// True when [smileProbability] ≥ 0.70.
  final bool isSmiling;

  /// Raw smile probability from ML Kit in the range [0.0, 1.0].
  final double smileProbability;

  /// Bounding box coordinates in original image pixel space.
  final Rect boundingBox;

  const FaceAnalysisResult({
    required this.faceNumber,
    required this.isSmiling,
    required this.smileProbability,
    required this.boundingBox,
  });

  /// Smile probability expressed as a percentage string, e.g. "72.3%".
  String get smilePercentageLabel =>
      '${(smileProbability * 100).toStringAsFixed(1)}%';

  /// Smile probability as a 0-100 number for progress bars.
  double get smilePercentageValue => (smileProbability * 100).clamp(0.0, 100.0);
}
