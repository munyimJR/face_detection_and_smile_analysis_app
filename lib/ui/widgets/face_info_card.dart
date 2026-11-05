import 'package:flutter/material.dart';
import '../../models/face_analysis_result.dart';

/// Displays per-face details: face number, smile status, and smile probability.
class FaceInfoCard extends StatelessWidget {
  final FaceAnalysisResult result;

  const FaceInfoCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmiling = result.isSmiling;
    final accentColor = isSmiling ? Colors.green : Colors.red;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Face number badge
            CircleAvatar(
              radius: 20,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              child: Text(
                '${result.faceNumber}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor.shade700,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Face info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Face ${result.faceNumber}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Smile Probability: ${result.smilePercentageLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Smile status chip
            Chip(
              avatar: Text(
                isSmiling ? '😊' : '😐',
                style: const TextStyle(fontSize: 14),
              ),
              label: Text(
                isSmiling ? 'Smiling' : 'Not Smiling',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accentColor.shade800,
                ),
              ),
              backgroundColor: accentColor.withValues(alpha: 0.1),
              side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

