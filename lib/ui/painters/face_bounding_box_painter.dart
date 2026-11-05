import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Draws labelled bounding boxes over detected faces, scaling from ML Kit's
/// original image coordinate space to the widget's display size.
class FaceBoundingBoxPainter extends CustomPainter {
  final List<Face> faces;

  /// Pixel dimensions of the original source image.
  final Size imageSize;

  /// Render dimensions of the widget displaying the image.
  final Size widgetSize;

  FaceBoundingBoxPainter({
    required this.faces,
    required this.imageSize,
    required this.widgetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == Size.zero) return;

    // Compute the actual displayed rect using BoxFit.contain logic.
    final imageAspect = imageSize.width / imageSize.height;
    final widgetAspect = widgetSize.width / widgetSize.height;

    double displayW, displayH, offsetX, offsetY;

    if (imageAspect > widgetAspect) {
      // Letterboxed top/bottom
      displayW = widgetSize.width;
      displayH = widgetSize.width / imageAspect;
      offsetX = 0;
      offsetY = (widgetSize.height - displayH) / 2;
    } else {
      // Pillarboxed left/right
      displayH = widgetSize.height;
      displayW = widgetSize.height * imageAspect;
      offsetY = 0;
      offsetX = (widgetSize.width - displayW) / 2;
    }

    final scaleX = displayW / imageSize.width;
    final scaleY = displayH / imageSize.height;

    final boxPaint = Paint()
      ..color = Colors.greenAccent.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < faces.length; i++) {
      final r = faces[i].boundingBox;
      final scaled = Rect.fromLTRB(
        offsetX + r.left * scaleX,
        offsetY + r.top * scaleY,
        offsetX + r.right * scaleX,
        offsetY + r.bottom * scaleY,
      );

      canvas.drawRect(scaled, boxPaint);

      // Label badge above the box
      final tp = TextPainter(
        text: TextSpan(
          text: ' Face ${i + 1} ',
          style: const TextStyle(
            color: Colors.white,
            backgroundColor: Color(0xFF00C853), // green-A700
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelY = (scaled.top - 16).clamp(0.0, size.height - 16);
      tp.paint(canvas, Offset(scaled.left, labelY));
    }
  }

  @override
  bool shouldRepaint(FaceBoundingBoxPainter old) =>
      old.faces != faces ||
      old.imageSize != imageSize ||
      old.widgetSize != widgetSize;
}

