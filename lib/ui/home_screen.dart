import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/face_detector_service.dart';
import '../models/face_analysis_result.dart';
import '../theme/theme_notifier.dart';
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

  Uint8List? _imageBytes;
  Size _imageSize = Size.zero;
  List<FaceAnalysisResult> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoNotice;
  bool _showLabelsOnImage = true;

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  // ── Analytics Computations ──────────────────────────────────────────────────

  int get _totalFaces => _results.length;

  int get _smilingFaces => _results.where((r) => r.isSmiling).length;

  int get _notSmilingFaces => _totalFaces - _smilingFaces;

  double get _smilingPercentageValue {
    if (_totalFaces == 0) return 0.0;
    return (_smilingFaces / _totalFaces) * 100.0;
  }

  String get _smilingPercentageLabel {
    if (_totalFaces == 0) return '0%';
    return '${_smilingPercentageValue.toStringAsFixed(1)}%';
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickAndAnalyze() async {
    try {
      // Limit resolution to 2048px for optimal performance, memory, and fast detection
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );

      if (picked == null) return; // User cancelled picker

      // Read image bytes reliably across all platforms (Web, Android, iOS, Windows, macOS, Linux)
      final bytes = await picked.readAsBytes();

      // Extract image dimensions for precise bounding box mapping
      Size decodedSize = const Size(800, 600);
      try {
        final decoded = await decodeImageFromList(bytes);
        decodedSize = Size(
          decoded.width.toDouble(),
          decoded.height.toDouble(),
        );
      } catch (e) {
        debugPrint('Dimension decode warning: $e');
      }

      // Update state immediately so the image is displayed with zero lag
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _imageSize = decodedSize;
          _isLoading = true;
          _errorMessage = null;
          _infoNotice = null;
          _results = [];
        });
      }

      // Perform face detection and smile analysis
      final detection = await _service.detect(
        imageFile: picked,
        imageSize: decodedSize,
      );

      if (mounted) {
        setState(() {
          _results = detection.results;
          _infoNotice = detection.infoMessage;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Image pick/analysis error: $e\n$stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Could not analyze image. Please make sure the file format is supported and try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Main Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _imageBytes != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Face Detection & Smile Analysis',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Powered by Google ML Kit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, themeMode, _) {
              final isDark = themeMode == ThemeMode.dark ||
                  (themeMode == ThemeMode.system &&
                      MediaQuery.platformBrightnessOf(context) ==
                          Brightness.dark);
              return IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      RotationTransition(turns: anim, child: child),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey<bool>(isDark),
                    color: isDark
                        ? const Color(0xFFFBBF24) // warm sun yellow
                        : theme.colorScheme.primary,
                  ),
                ),
                tooltip: isDark
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
                onPressed: () {
                  themeModeNotifier.value =
                      isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notice banner (e.g. desktop/web preview notice)
              if (_infoNotice != null) ...[
                _buildInfoBanner(_infoNotice!),
                const SizedBox(height: 16),
              ],

              // Error banner if any
              if (_errorMessage != null) ...[
                _buildErrorBanner(_errorMessage!),
                const SizedBox(height: 16),
              ],

              // Upload / Image Preview Zone
              if (!hasImage)
                _buildEmptyUploadZone()
              else
                _buildLoadedImageZone(),

              const SizedBox(height: 24),

              // Analytics Summary Cards
              if (hasImage && !_isLoading) ...[
                _buildAnalyticsSection(),
                const SizedBox(height: 24),
                _buildFaceBreakdownSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Upload / Image Preview Components ──────────────────────────────────────

  Widget _buildEmptyUploadZone() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainer
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_rounded,
              size: 36,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Upload Image to Analyze',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select any photo containing one or multiple faces\nto detect face counts and smile probabilities',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Format Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['JPG', 'PNG', 'WEBP']
                .map(
                  (fmt) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fmt,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),

          // Primary Upload Button
          FilledButton.icon(
            onPressed: _pickAndAnalyze,
            icon: const Icon(Icons.photo_library_rounded, size: 20),
            label: const Text(
              'Select from Gallery',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedImageZone() {
    final theme = Theme.of(context);
    final aspectRatio = (_imageSize.width > 0 && _imageSize.height > 0)
        ? _imageSize.width / _imageSize.height
        : 4 / 3;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Action Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Uploaded Image',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_results.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_totalFaces ${_totalFaces == 1 ? "Face" : "Faces"}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),

                // Toggle labels button
                if (_results.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      _showLabelsOnImage
                          ? Icons.label_rounded
                          : Icons.label_off_rounded,
                      size: 20,
                    ),
                    tooltip: 'Toggle Bounding Labels',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _showLabelsOnImage = !_showLabelsOnImage;
                      });
                    },
                  ),

                // Re-upload Button
                TextButton.icon(
                  onPressed: _isLoading ? null : _pickAndAnalyze,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Change'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Image Viewport with Bounding Boxes
          AspectRatio(
            aspectRatio: aspectRatio.clamp(0.6, 2.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Render Image & Bounding Boxes with RepaintBoundary for optimal painting performance
                RepaintBoundary(
                  child: ImageWithBoundingBoxes(
                    imageBytes: _imageBytes!,
                    results: _results,
                    imageSize: _imageSize,
                    showLabels: _showLabelsOnImage,
                  ),
                ),

                // Loading Frosted Overlay
                if (_isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Scanning faces with Google ML Kit…',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Calculating smile probabilities',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Upload Another Image Bottom Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickAndAnalyze,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Upload Another Image'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Analytics Section ──────────────────────────────────────────────────────

  Widget _buildAnalyticsSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Detection Analytics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row of 2 Analytics Cards
        Row(
          children: [
            // Total Faces Card
            Expanded(
              child: AnalyticsCard(
                label: 'Total Faces',
                value: '$_totalFaces',
                subtitle: _totalFaces == 0
                    ? 'No faces found'
                    : '$_totalFaces ${_totalFaces == 1 ? "face" : "faces"} detected',
                icon: Icons.face_rounded,
                accentColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),

            // Smiling Percentage Card
            Expanded(
              child: AnalyticsCard(
                label: 'Smiling Percentage',
                value: _smilingPercentageLabel,
                subtitle: _totalFaces > 0
                    ? '($_smilingFaces / $_totalFaces) × 100'
                    : 'Threshold: ≥ 70%',
                icon: Icons.sentiment_very_satisfied_rounded,
                accentColor: const Color(0xFF10B981),
                progress: _totalFaces > 0 ? (_smilingPercentageValue / 100) : 0,
              ),
            ),
          ],
        ),

        // Smile Ratio Segmented Bar
        if (_totalFaces > 0) ...[
          const SizedBox(height: 12),
          _buildSmileRatioBar(),
        ],
      ],
    );
  }

  Widget _buildSmileRatioBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('😊', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Smiling: $_smilingFaces',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('😐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Not Smiling: $_notSmilingFaces',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF43F5E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (_smilingFaces > 0)
                    Expanded(
                      flex: _smilingFaces,
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (_notSmilingFaces > 0)
                    Expanded(
                      flex: _notSmilingFaces,
                      child: Container(color: const Color(0xFFF43F5E)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Individual Face Breakdown ──────────────────────────────────────────────

  Widget _buildFaceBreakdownSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.badge_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Individual Face Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_totalFaces',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_results.isEmpty)
          _buildNoFacesCard()
        else
          ..._results.map((res) => FaceInfoCard(result: res)),
      ],
    );
  }

  Widget _buildNoFacesCard() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.face_retouching_off_rounded,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No faces detected',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try uploading a clearer portrait or group photo with good lighting.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _errorMessage = null),
            visualDensity: VisualDensity.compact,
            color: const Color(0xFF991B1B),
          ),
        ],
      ),
    );
  }
}
