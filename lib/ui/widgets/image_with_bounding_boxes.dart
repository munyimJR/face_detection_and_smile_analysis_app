import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../painters/face_bounding_box_painter.dart';

/// Displays [imageFile] with bounding boxes overlaid for each detected [face].
///
/// The painter accounts for BoxFit.contain letterboxing/pillarboxing so boxes
/// align precisely with where the image pixels are actually rendered.
class ImageWithBoundingBoxes extends StatelessWidget {
  final File imageFile;
  final List<Face> faces;
  final Size imageSize;

  const ImageWithBoundingBoxes({
    super.key,
    required this.imageFile,
    required this.faces,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(imageFile, fit: BoxFit.contain),
            CustomPaint(
              painter: FaceBoundingBoxPainter(
                faces: faces,
                imageSize: imageSize,
                widgetSize: widgetSize,
              ),
            ),
          ],
        );
      },
    );
  }
}

