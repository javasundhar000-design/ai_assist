import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class CaptureLookScreen extends StatelessWidget {
  final Outfit outfit;
  final String? capturedImagePath;
  const CaptureLookScreen({super.key, required this.outfit, this.capturedImagePath});

  @override
  Widget build(BuildContext context) {
    final hasRealPhoto = capturedImagePath != null && File(capturedImagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Capture Look', style: AppTextStyles.h1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                hasRealPhoto
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        child: Image.file(
                          File(capturedImagePath!),
                          height: 420,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : FashionImagePlaceholder(
                        accent: outfit.accent,
                        icon: Icons.checkroom,
                        height: 420,
                        width: double.infinity,
                        borderRadius: AppRadii.lg,
                      ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: FashionScoreBadge(score: outfit.fashionScore, size: 52),
                ),
              ],
            ),
            if (!hasRealPhoto) ...[
              const SizedBox(height: 10),
              Text(
                'Photo unavailable — the camera couldn\'t be captured this time, but your look was still saved to History.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text('Look Captured Successfully!', style: AppTextStyles.h2),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${outfit.name} • ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    label: 'View in Gallery',
                    icon: Icons.photo_library_outlined,
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlineActionButton(
                    label: 'Share',
                    icon: Icons.ios_share,
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Just styled "${outfit.name}" with a ${outfit.fashionScore}/100 fashion score using AURA STYLIST AI ✨',
                        files: hasRealPhoto ? [XFile(capturedImagePath!)] : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
