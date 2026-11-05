import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../services/face_detector_service.dart';
import '../models/face_analysis_result.dart';
import 'widgets/image_with_bounding_boxes.dart';
import 'widgets/analytics_card.dart';
import 'widgets/face_info_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  final _service = FaceDetectorService();

  File? _imageFile;
  Size _imageSize = Size.zero;
  List<Face> _faces = [];
  List<FaceAnalysisResult> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  // ── Computed analytics ─────────────────────────────────────────────────────

  int get _totalFaces => _faces.length;

  String get _smilingPercentageLabel {
    if (_totalFaces == 0) return '0%';
    final smiling = _results.where((r) => r.isSmiling).length;
    final pct = (smiling / _totalFaces) * 100;
    return '${pct.toStringAsFixed(1)}%';
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickAndAnalyze() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return; // User cancelled

    final file = File(picked.path);

    // Decode image dimensions for correct bounding-box coordinate scaling.
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final imgSize = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _imageFile = file;
      _imageSize = imgSize;
      _faces = [];
      _results = [];
    });

    try {
      final detection = await _service.detect(file);
      if (mounted) {
        setState(() {
          _faces = detection.faces;
          _results = detection.results;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Detection failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Face Detection & Smile Analysis'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUploadButton(),
            const SizedBox(height: 16),
            _buildImagePreview(),
            if (_imageFile != null && !_isLoading) ...[
              const SizedBox(height: 20),
              _buildAnalyticsRow(),
              const SizedBox(height: 20),
              _buildFaceInfoSection(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Sub-builders ───────────────────────────────────────────────────────────

  Widget _buildUploadButton() {
    return FilledButton.icon(
      onPressed: _isLoading ? null : _pickAndAnalyze,
      icon: const Icon(Icons.photo_library_outlined),
      label: Text(
        _imageFile != null ? 'Upload Another Image' : 'Upload Image',
        style: const TextStyle(fontSize: 15),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildImagePreview() {
    // Empty placeholder
    if (_imageFile == null) {
      return _EmptyImagePlaceholder(onTap: _pickAndAnalyze);
    }

    // Loading state
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: _imageSize == Size.zero
            ? 4 / 3
            : _imageSize.width / _imageSize.height,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Analysing faces…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return _ErrorBanner(message: _errorMessage!, onRetry: _pickAndAnalyze);
    }

    // Image + bounding boxes
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _imageSize == Size.zero
            ? 4 / 3
            : _imageSize.width / _imageSize.height,
        child: ImageWithBoundingBoxes(
          imageFile: _imageFile!,
          faces: _faces,
          imageSize: _imageSize,
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow() {
    return Row(
      children: [
        Expanded(
          child: AnalyticsCard(
            label: 'Total Faces',
            value: '$_totalFaces',
            icon: Icons.face_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnalyticsCard(
            label: 'Smiling\nPercentage',
            value: _smilingPercentageLabel,
            icon: Icons.sentiment_satisfied_alt_outlined,
            color: Colors.green.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFaceInfoSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Individual Face Information',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (_faces.isEmpty)
          _NoFacesMessage()
        else
          ..._results.map((r) => FaceInfoCard(result: r)),
      ],
    );
  }
}

// ── Private helper widgets ──────────────────────────────────────────────────

class _EmptyImagePlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyImagePlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              'Tap to select an image',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _NoFacesMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.face_retouching_off_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No faces detected in this image.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

