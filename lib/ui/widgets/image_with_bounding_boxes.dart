import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/face_analysis_result.dart';
import '../painters/face_bounding_box_painter.dart';

/// Displays the uploaded image with scaled bounding boxes overlaid for each detected face.
class ImageWithBoundingBoxes extends StatelessWidget {
  final File? imageFile;
  final Uint8List? imageBytes;
  final List<FaceAnalysisResult> results;
  final Size imageSize;
  final bool showLabels;

  const ImageWithBoundingBoxes({
    super.key,
    this.imageFile,
    this.imageBytes,
    required this.results,
    required this.imageSize,
    this.showLabels = true,
  }) : assert(imageFile != null || imageBytes != null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetSize = Size(constraints.maxWidth, constraints.maxHeight);

        Widget imageWidget;
        if (imageBytes != null) {
          imageWidget = Image.memory(
            imageBytes!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          );
        } else {
          imageWidget = Image.file(
            imageFile!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // Base Image
            imageWidget,

            // AI Bounding Box Layer
            CustomPaint(
              painter: FaceBoundingBoxPainter(
                results: results,
                imageSize: imageSize,
                widgetSize: widgetSize,
                showLabels: showLabels,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          const Text(
            'Unable to render image',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
