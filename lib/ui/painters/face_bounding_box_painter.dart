import 'package:flutter/material.dart';
import '../../models/face_analysis_result.dart';

/// Draws modern, AI reticle-style bounding boxes over detected faces,
/// scaling accurately from ML Kit's image coordinate space to the displayed widget size.
class FaceBoundingBoxPainter extends CustomPainter {
  final List<FaceAnalysisResult> results;

  /// Pixel dimensions of the original source image.
  final Size imageSize;

  /// Render dimensions of the widget displaying the image.
  final Size widgetSize;

  /// Whether to display badge labels above each box.
  final bool showLabels;

  FaceBoundingBoxPainter({
    required this.results,
    required this.imageSize,
    required this.widgetSize,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == Size.zero || widgetSize == Size.zero || results.isEmpty) {
      return;
    }

    // BoxFit.contain letterbox & pillarbox computation.
    final imageAspect = imageSize.width / imageSize.height;
    final widgetAspect = widgetSize.width / widgetSize.height;

    double displayW, displayH, offsetX, offsetY;

    if (imageAspect > widgetAspect) {
      // Letterboxed top and bottom
      displayW = widgetSize.width;
      displayH = widgetSize.width / imageAspect;
      offsetX = 0;
      offsetY = (widgetSize.height - displayH) / 2;
    } else {
      // Pillarboxed left and right
      displayH = widgetSize.height;
      displayW = widgetSize.height * imageAspect;
      offsetY = 0;
      offsetX = (widgetSize.width - displayW) / 2;
    }

    final scaleX = displayW / imageSize.width;
    final scaleY = displayH / imageSize.height;

    for (final face in results) {
      final r = face.boundingBox;
      final scaled = Rect.fromLTRB(
        offsetX + r.left * scaleX,
        offsetY + r.top * scaleY,
        offsetX + r.right * scaleX,
        offsetY + r.bottom * scaleY,
      );

      final isSmiling = face.isSmiling;
      final primaryColor = isSmiling
          ? const Color(0xFF10B981) // Modern Emerald Green
          : const Color(0xFFF43F5E); // Modern Coral Rose

      final rrect = RRect.fromRectAndRadius(scaled, const Radius.circular(8));

      // 1. Subtle translucent face region highlight
      final fillPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, fillPaint);

      // 2. High-tech bounding box stroke
      final strokePaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(rrect, strokePaint);

      // 3. AI Camera Reticle corner brackets
      final cornerPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      final cornerLen = (scaled.width * 0.16).clamp(10.0, 24.0);

      // Top-Left corner
      canvas.drawLine(
        scaled.topLeft,
        Offset(scaled.left + cornerLen, scaled.top),
        cornerPaint,
      );
      canvas.drawLine(
        scaled.topLeft,
        Offset(scaled.left, scaled.top + cornerLen),
        cornerPaint,
      );

      // Top-Right corner
      canvas.drawLine(
        scaled.topRight,
        Offset(scaled.right - cornerLen, scaled.top),
        cornerPaint,
      );
      canvas.drawLine(
        scaled.topRight,
        Offset(scaled.right, scaled.top + cornerLen),
        cornerPaint,
      );

      // Bottom-Left corner
      canvas.drawLine(
        scaled.bottomLeft,
        Offset(scaled.left + cornerLen, scaled.bottom),
        cornerPaint,
      );
      canvas.drawLine(
        scaled.bottomLeft,
        Offset(scaled.left, scaled.bottom - cornerLen),
        cornerPaint,
      );

      // Bottom-Right corner
      canvas.drawLine(
        scaled.bottomRight,
        Offset(scaled.right - cornerLen, scaled.bottom),
        cornerPaint,
      );
      canvas.drawLine(
        scaled.bottomRight,
        Offset(scaled.right, scaled.bottom - cornerLen),
        cornerPaint,
      );

      // 4. Floating badge with face index, emoji, and probability percentage
      if (showLabels) {
        final emoji = isSmiling ? '😊' : '😐';
        final textSpan = TextSpan(
          children: [
            TextSpan(
              text: 'Face ${face.faceNumber}  ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: '$emoji ${face.smilePercentageLabel}',
              style: TextStyle(
                color: isSmiling
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFFECDD3),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final badgeHeight = tp.height + 6;
        final badgeWidth = tp.width + 14;

        double badgeY = scaled.top - badgeHeight - 4;
        if (badgeY < offsetY) {
          // If badge overflows above visible image, position it just inside the top
          badgeY = scaled.top + 5;
        }

        final badgeX =
            scaled.left.clamp(offsetX + 4, offsetX + displayW - badgeWidth - 4);

        final badgeRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(badgeX, badgeY, badgeWidth, badgeHeight),
          const Radius.circular(6),
        );

        // Badge dark glass background
        final badgeBgPaint = Paint()
          ..color = const Color(0xE60F172A)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(badgeRect, badgeBgPaint);

        // Badge border
        final badgeBorderPaint = Paint()
          ..color = primaryColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawRRect(badgeRect, badgeBorderPaint);

        tp.paint(canvas, Offset(badgeX + 7, badgeY + 3));
      }
    }
  }

  @override
  bool shouldRepaint(FaceBoundingBoxPainter old) =>
      old.results != results ||
      old.imageSize != imageSize ||
      old.widgetSize != widgetSize ||
      old.showLabels != showLabels;
}
